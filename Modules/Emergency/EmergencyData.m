#import "EmergencyData.h"
#import "MITJSON.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "EmergencyModule.h"
#import "MobileRequestOperation.h"

@implementation EmergencyData

@synthesize primaryPhoneNumbers, allPhoneNumbers;

@dynamic htmlString, lastUpdated, lastFetched;

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
        primaryPhoneNumbers = @[@{@"title" : @"Campus Police",
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
    info = [[CoreDataManager fetchDataForAttribute:EmergencyInfoEntityName] lastObject];
    
    if (!info) {
        info = [CoreDataManager insertNewObjectForEntityForName:EmergencyInfoEntityName];
        [info setValue:@"" forKey:@"htmlString"];
        [info setValue:[NSDate distantPast] forKey:@"lastUpdated"];
        [info setValue:[NSDate distantPast] forKey:@"lastFetched"];
    }
}

- (void)fetchContacts {
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES];
    allPhoneNumbers = [CoreDataManager objectsForEntity:EmergencyContactEntityName
                                      matchingPredicate:predicate
                                        sortDescriptors:@[sortDescriptor]];
    if (!allPhoneNumbers) {
        allPhoneNumbers = [[NSArray alloc] init];
    }
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
	return ([[info valueForKey:@"htmlString"] length] == 0);
}

- (NSDate *)lastUpdated {
    return [info valueForKey:@"lastUpdated"];
}

- (NSDate *)lastFetched {
    return [info valueForKey:@"lastFetched"];
}

- (NSString *)htmlString {
    NSDate *lastUpdated = [info valueForKey:@"lastUpdated"];
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
    
    NSArray *keys = [NSArray arrayWithObjects:@"__BODY__", @"__POST_DATE__", nil];
    
    NSArray *values = [NSArray arrayWithObjects:[info valueForKey:@"htmlString"], lastUpdatedString, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Server requests

// Send request
- (void)checkForEmergencies {
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"emergency" command:nil parameters:nil];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:self];

        } else {
            if (![jsonResult isKindOfClass:[NSArray class]]) {
                DDLogError(@"%@ received json result as %@, not NSArray.", NSStringFromClass([self class]), NSStringFromClass([jsonResult class]));
            } else {
                NSDictionary *response = [(NSArray *)jsonResult lastObject];
                
                NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[[response objectForKey:@"unixtime"] doubleValue]];
                NSDate *previouslyUpdated = [info valueForKey:@"lastUpdated"];
                
                if (!previouslyUpdated) { // user has never opened the app, set a baseline date
                    [self setLastRead:[NSDate date]];
                }
                
                if (!previouslyUpdated || [lastUpdated timeIntervalSinceDate:previouslyUpdated] > 0) {
                    [info setValue:lastUpdated forKey:@"lastUpdated"];
                    [info setValue:[NSDate date] forKey:@"lastFetched"];
                    [info setValue:[response objectForKey:@"text"] forKey:@"htmlString"];
                    [CoreDataManager saveData];
                    
                    [self fetchEmergencyInfo];
                    // notify listeners that this is a new emergency
                    
                    //[[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:self];
                }
                // notify listeners that the info is done loading, regardless of whether it's changed
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:self];
            }
        }
    };
    [[NSOperationQueue mainQueue] addOperation:request];
}

// request contacts
- (void)reloadContacts {
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"emergency"
                                                                              command:@"contacts"
                                                                           parameters:nil];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error && [jsonResult isKindOfClass:[NSArray class]]) {
                NSArray *contactsArray = (NSArray *)jsonResult;
                
                // delete all of the old numbers
                NSArray *oldContacts = [CoreDataManager fetchDataForAttribute:EmergencyContactEntityName];
                if ([oldContacts count] > 0) {
                    [CoreDataManager deleteObjects:oldContacts];
                }
                
                // create new entry for each contact in contacts
                NSInteger i = 0;
                for (NSDictionary *contactDict in contactsArray) {
                    NSManagedObject *contact = [CoreDataManager insertNewObjectForEntityForName:EmergencyContactEntityName];
                    [contact setValue:[contactDict objectForKey:@"contact"] forKey:@"title"];
                    [contact setValue:[contactDict objectForKey:@"description"] forKey:@"summary"];
                    [contact setValue:[contactDict objectForKey:@"phone"] forKey:@"phone"];
                    [contact setValue:[NSNumber numberWithInteger:i] forKey:@"ordinality"];
                    i++;
                }
                [CoreDataManager saveData];
                [self fetchContacts];
                
                // notify listeners that contacts have finished loading
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyContactsDidLoadNotification object:self];
        } else {
            
        }
    };
    [[NSOperationQueue mainQueue] addOperation:request];

}

@end
