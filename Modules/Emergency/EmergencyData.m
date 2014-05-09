#import "EmergencyData.h"
#import "MITJSON.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "EmergencyModule.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface EmergencyData ()
@property (nonatomic,copy) NSArray *allPhoneNumbers;
@property (nonatomic, copy) NSArray *primaryPhoneNumbers;
@property (copy) NSArray *contacts;
@property (strong) NSManagedObject *info;
@end

@implementation EmergencyData
@dynamic htmlString;
@dynamic lastUpdated;
@dynamic lastFetched;

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
        self.primaryPhoneNumbers = @[@{@"title" : @"Campus Police",
                                       @"phone" : @"617.253.1212"},
                                     @{@"title" : @"MIT Medical",
                                       @"phone" : @"617.253.1311"},
                                     @{@"title" : @"Emergency Status",
                                       @"phone" : @"617.253.7669"}];
        [self fetchEmergencyInfo];
        [self fetchContacts];
        
        [self checkForEmergencies];
        [self reloadContacts];
    }
    return self;
}

- (void)fetchEmergencyInfo {
    self.info = [[CoreDataManager fetchDataForAttribute:EmergencyInfoEntityName] lastObject];
    
    if (!self.info) {
        self.info = [CoreDataManager insertNewObjectForEntityForName:EmergencyInfoEntityName];
        [self.info setValue:@"" forKey:@"htmlString"];
        [self.info setValue:[NSDate distantPast] forKey:@"lastUpdated"];
        [self.info setValue:[NSDate distantPast] forKey:@"lastFetched"];
    }
}

- (void)fetchContacts {
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES];
    self.allPhoneNumbers = [CoreDataManager objectsForEntity:EmergencyContactEntityName
                                      matchingPredicate:predicate
                                        sortDescriptors:@[sortDescriptor]];
}


#pragma mark -
#pragma mark Accessors

- (BOOL) didReadMessage {
    NSDate *lastUpdate = [self lastUpdated];
    NSDate *lastRead = [self lastRead];
#ifdef DEBUG
    NSTimeInterval timeout = 60 * 30;
#else
    NSTimeInterval timeout = 24 * 60 * 60 * 7;
#endif
    // return YES if this is a first install, lastUpdate is over a week old, or user has read the message since lastUpdate
    return ([self hasNeverLoaded] || -[lastUpdate timeIntervalSinceNow] > timeout || [lastRead timeIntervalSinceDate:lastUpdate] > 0);
}

- (NSDate *)lastRead {
    return [[NSUserDefaults standardUserDefaults] objectForKey:EmergencyMessageLastRead];
}

- (void)setLastRead:(NSDate *)date {
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:EmergencyMessageLastRead];
}

- (BOOL) hasNeverLoaded {
	return ([[self.info valueForKey:@"htmlString"] length] == 0);
}

- (NSDate *)lastUpdated {
    return [self.info valueForKey:@"lastUpdated"];
}

- (NSDate *)lastFetched {
    return [self.info valueForKey:@"lastFetched"];
}

- (NSString *)htmlString {
    NSDate *lastUpdated = [self.info valueForKey:@"lastUpdated"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/y h:mm a zz"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *lastUpdatedString = [formatter stringFromDate:lastUpdated];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"emergency_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        DDLogError(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
        return nil;
    }
    
    NSDictionary *templates = @{@"__BODY__" : [self.info valueForKey:@"htmlString"],
                                @"__POST_DATE__" : lastUpdatedString};
    [htmlString replaceOccurrencesOfStrings:[templates allKeys] withStrings:[templates allValues] options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Server requests

// Send request
- (void)checkForEmergencies {
    NSURLRequest *request = [NSURLRequest requestForModule:@"emergency" command:nil parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak EmergencyData *weakSelf = self;
    [requestOperation setCompleteBlock:^(MITTouchstoneRequestOperation *operation, NSArray *emergencyObjects, NSString *contentType, NSError *error) {
        EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"request for v2:%@ failed with error %@",@"emergency",[error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:blockSelf];
        } else if (![emergencyObjects isKindOfClass:[NSArray class]]) {
            NSString *message = [NSString stringWithFormat:@"request for v2:%@ failed, got response object of class %@, expected %@",@"emergency",NSStringFromClass([emergencyObjects class]),NSStringFromClass([NSArray class])];
            DDLogWarn(@"%@",message);

            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:blockSelf];
        } else {
            NSArray *sortedEmergencyObjects = [emergencyObjects sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *object1, NSDictionary *object2) {

                NSNumber *lastUpdated1 = object1[@"unixtime"];
                NSNumber *lastUpdated2 = object2[@"unixtime"];

                return [lastUpdated1 compare:lastUpdated2];
            }];

            NSDictionary *mostRecentEmergency = [sortedEmergencyObjects lastObject];
            NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[mostRecentEmergency[@"unixtime"] doubleValue]];
            NSDate *previouslyUpdated = [blockSelf.info valueForKey:@"lastUpdated"];

            if (!previouslyUpdated) { // user has never opened the app, set a baseline date
                [blockSelf setLastRead:[NSDate date]];
            }

            if (!previouslyUpdated || [lastUpdated timeIntervalSinceDate:previouslyUpdated] > 0) {
                [blockSelf.info setValue:lastUpdated forKey:@"lastUpdated"];
                [blockSelf.info setValue:[NSDate date] forKey:@"lastFetched"];
                [blockSelf.info setValue:mostRecentEmergency[@"text"] forKey:@"htmlString"];
                [CoreDataManager saveData];

                [blockSelf fetchEmergencyInfo];
                // notify listeners that this is a new emergency
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:blockSelf];
            }

            // notify listeners that the info is done loading, regardless of whether it's changed
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:blockSelf];
        }
    }];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

// request contacts
- (void)reloadContacts {
    NSURLRequest *request = [NSURLRequest requestForModule:@"emergency" command:@"contacts" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak EmergencyData *weakSelf = self;
    [requestOperation setCompleteBlock:^(MITTouchstoneRequestOperation *operation, NSArray *contacts, NSString *contentType, NSError *error) {
        EmergencyData *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            DDLogWarn(@"request failed for v2:%@/%@ with error %@",@"emergency",@"contacts",[error localizedDescription]);
        } else if (![contacts isKindOfClass:[NSArray class]]) {
            DDLogWarn(@"request failed for v2:%@/%@: z",@"emergency",@"contacts");
        } else {
            // delete all of the old numbers
            NSArray *oldContacts = [CoreDataManager fetchDataForAttribute:EmergencyContactEntityName];
            if ([oldContacts count]) {
                [CoreDataManager deleteObjects:oldContacts];
            }
            
            [contacts enumerateObjectsUsingBlock:^(NSDictionary *contact, NSUInteger idx, BOOL *stop) {
                NSManagedObject *contactObject = [CoreDataManager insertNewObjectForEntityForName:EmergencyContactEntityName];
                [contactObject setValue:contact[@"contact"] forKey:@"title"];
                [contactObject setValue:contact[@"description"] forKey:@"summary"];
                [contactObject setValue:contact[@"phone"] forKey:@"phone"];
                [contactObject setValue:@(idx) forKey:@"ordinality"];
            }];
            
            [CoreDataManager saveData];
            [self fetchContacts];
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsDidLoadNotification object:self];
        }
    }];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];

}

@end
