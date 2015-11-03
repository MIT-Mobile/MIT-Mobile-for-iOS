#import "EmergencyData.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "EmergencyModule.h"
#import "MITEmergencyInfoWebservices.h"
#import "MITEmergencyInfoAnnouncement.h"
#import "MITEmergencyInfoContact.h"
#import "MITCoreData.h"

@interface EmergencyData ()
@property (nonatomic,copy) NSArray *allPhoneNumbers;
@property (nonatomic, copy) NSDictionary *campusPolicePhoneNumber;
@property (nonatomic, copy) NSDictionary *medicalPhoneNumber;
@property (nonatomic, copy) NSDictionary *emergencyResponseGuideLink;
@property (nonatomic, copy) NSDictionary *emergencyStatusPhoneNumber;
@property (nonatomic, copy) NSArray *primaryItems;
@property (copy) NSArray *contacts;
@property (nonatomic, strong) NSString *announcementHTML;
@property (nonatomic, strong) NSDate *publishedAt;
@end

@implementation EmergencyData
@dynamic htmlString;

NSString * const EmergencyMessageLastRead = @"EmergencyLastRead";

#pragma mark -
#pragma mark Singleton Boilerplate

+ (EmergencyData *)sharedData {
    static EmergencyData *sharedEmergencyData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEmergencyData = [[self alloc] init];
    });

    return sharedEmergencyData;
}
#pragma mark -
#pragma mark Initialization
- (id) init {
    self = [super init];
    if (self != nil) {
        // TODO: get primary numbers from m.mit.edu (it's unlikely, but numbers might change)
        self.campusPolicePhoneNumber = @{@"title" : @"Campus Police",
                                         @"phone" : @"617.253.1212"};
        self.medicalPhoneNumber = @{@"title" : @"MIT Medical",
                                    @"phone" : @"617.253.1311"};
        self.emergencyResponseGuideLink = @{@"title" : @"Emergency Response Guide",
                                            @"url" : @"http://ehs.mit.edu/emergency/"};
        self.emergencyStatusPhoneNumber = @{@"title" : @"Emergency Status",
                                            @"phone" : @"617.253.7669"};
        self.primaryItems = @[self.campusPolicePhoneNumber,
                              self.medicalPhoneNumber,
                              self.emergencyResponseGuideLink,
                              self.emergencyStatusPhoneNumber];
        [self fetchContacts];
        
        [self checkForEmergencies];
        [self reloadContacts];
    }
    return self;
}

- (void)fetchContacts {
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
    
    [context performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:EmergencyContactEntityName];
        fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES]];
        
        NSError *error = nil;
        NSArray *contacts = [context executeFetchRequest:fetchRequest error:&error];
        
        if (!contacts) {
            DDLogError(@"failed to fetch emergency contacts: %@",error);
        } else {
            self.allPhoneNumbers = contacts;
        }
    }];
}

#pragma mark -
#pragma mark Accessors

- (NSString *)htmlString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/y h:mm a zz"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *lastUpdatedString = [formatter stringFromDate:self.publishedAt];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"emergency_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
        return nil;
    }
    if (!self.announcementHTML) {
        return nil;
    }
    if (!lastUpdatedString) {
        lastUpdatedString = @"";
    }
    
    NSDictionary *templates = @{@"__BODY__" : self.announcementHTML,
                                @"__POST_DATE__" : lastUpdatedString};
    [htmlString replaceOccurrencesOfStrings:[templates allKeys] withStrings:[templates allValues] options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Server requests

// Send request
- (void)checkForEmergencies
{
    __weak EmergencyData *weakSelf = self;
    [MITEmergencyInfoWebservices getEmergencyAnnouncement:^(MITEmergencyInfoAnnouncement *announcement, NSError *error) {
        EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"emergency announcement request failed with error %@",error);
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:blockSelf];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.publishedAt = announcement.publishedAt;
            
                self.announcementHTML = announcement.announcementHTML;
            
                // notify listeners that this is a new emergency
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:blockSelf];
            
                // notify listeners that the info is done loading, regardless of whether it's changed
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:blockSelf];
            }];
        }
    }];
}

// request contacts
- (void)reloadContacts
{
    __weak EmergencyData *weakSelf = self;
    [MITEmergencyInfoWebservices getEmergencyContacts:^(NSArray *contacts, NSError *error) {
        EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"request failed for :%@/%@ with error %@",@"emergency",@"contacts",error);
        } else {
            NSManagedObjectContext *updateContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:NO];
            
            [updateContext performBlock:^{
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:EmergencyContactEntityName];
                
                NSError *error = nil;
                NSArray *existingContacts = [updateContext executeFetchRequest:fetchRequest error:&error];
                if (!existingContacts) {
                    DDLogError(@"failed to remove existing emergency contacts from persistent store: %@", error);
                } else {
                    [existingContacts enumerateObjectsUsingBlock:^(NSManagedObject *contact, NSUInteger idx, BOOL *stop) {
                        [updateContext deleteObject:contact];
                    }];
                }
                
                [contacts enumerateObjectsUsingBlock:^(MITEmergencyInfoContact *contact, NSUInteger idx, BOOL *stop) {
                    NSManagedObject *contactObject = [updateContext insertNewObjectForEntityForName:EmergencyContactEntityName];
                    [contactObject setValue:contact.name forKey:@"title"];
                    [contactObject setValue:contact.descriptionText forKey:@"summary"];
                    [contactObject setValue:contact.phone forKey:@"phone"];
                    [contactObject setValue:@(idx) forKey:@"ordinality"];
                }];
                
                BOOL success = [updateContext save:&error];
                if (!success) {
                    DDLogError(@"failed to update emergency contacts: %@",error);
                } else {
                    [self fetchContacts];
                    [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsDidLoadNotification object:self];
                }
            }];
        }
    }];
}

@end
