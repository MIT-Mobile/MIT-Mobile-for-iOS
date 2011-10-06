#import "EmergencyData.h"
#import "MITJSON.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "MITMobileWebAPI.h"
#import "Foundation+MITAdditions.h"
#import "EmergencyModule.h"

@implementation EmergencyData

@synthesize primaryPhoneNumbers, allPhoneNumbers, infoConnection, contactsConnection;

@dynamic htmlString, lastUpdated, lastFetched;

NSString * const EmergencyMessageLastRead = @"EmergencyLastRead";

#pragma mark -
#pragma mark Singleton Boilerplate

static EmergencyData *sharedEmergencyData = nil;

+ (EmergencyData *)sharedData {
    @synchronized(self) {
        if (sharedEmergencyData == nil) {
            sharedEmergencyData = [[super allocWithZone:NULL] init]; // assignment not done here
        }
    }
    return sharedEmergencyData;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedData] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Initialization

- (id) init {
    self = [super init];
    if (self != nil) {
        // TODO: get primary numbers from m.mit.edu (it's unlikely, but numbers might change)
        primaryPhoneNumbers = [[NSArray arrayWithObjects:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Campus Police", @"title",
                                     @"617.253.1212", @"phone",
                                     nil],
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"MIT Medical", @"title",
                                     @"617.253.1311", @"phone",
                                     nil],
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"Emergency Status", @"title",
                                     @"617.253.7669", @"phone",
                                     nil],
                                    nil] retain];
        [self fetchEmergencyInfo];
        [self fetchContacts];
        
        [self checkForEmergencies];
        [self reloadContacts];
    }
    return self;
}

- (void)fetchEmergencyInfo {
    info = [[[CoreDataManager fetchDataForAttribute:EmergencyInfoEntityName] lastObject] retain];
    if (!info) {
        info = [[CoreDataManager insertNewObjectForEntityForName:EmergencyInfoEntityName] retain];
        [info setValue:@"" forKey:@"htmlString"];
        [info setValue:[NSDate distantPast] forKey:@"lastUpdated"];
        [info setValue:[NSDate distantPast] forKey:@"lastFetched"];
    }
}

- (void)fetchContacts {
    [allPhoneNumbers release];
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES] autorelease];
    allPhoneNumbers = [[CoreDataManager objectsForEntity:EmergencyContactEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sortDescriptor]] retain];
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
    [formatter release];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath] isDirectory:YES];
    NSURL *fileURL = [NSURL URLWithString:@"emergency_template.html" relativeToURL:baseURL];
    
    NSError *error = nil;
    NSMutableString *htmlString = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!htmlString) {
        ELog(@"Failed to load template at %@. %@", fileURL, [error userInfo]);
        return nil;
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"__BODY__", @"__POST_DATE__", nil];
    
    NSArray *values = [NSArray arrayWithObjects:[info valueForKey:@"htmlString"], lastUpdatedString, nil];
    
    [htmlString replaceOccurrencesOfStrings:keys withStrings:values options:NSLiteralSearch];
    
    return htmlString;
}

#pragma mark -
#pragma mark Asynchronous HTTP - preferred

// Send request
- (void)checkForEmergencies {
    if (infoRequest != nil) {
        return;
    }

    infoRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
    BOOL dispatchedSuccessfully = [infoRequest requestObject:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", nil]];
    if (!dispatchedSuccessfully) {
        DLog(@"failed to fetch emergency info");
    }
    
    /*
    if ([self.infoConnection isConnected]) {
        return; // a connection already exists
    }
    // TODO: use Reachability to wait until app gets a connection to perform check
    self.infoConnection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    NSURL *url = [MITMobileWebAPI buildURL:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", nil]
								 queryBase:MITMobileWebAPIURLString];
    BOOL dispatchedSuccessfully = [infoConnection requestDataFromURL:url];
    if (dispatchedSuccessfully) {
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
    }
    */
}

// request contacts
- (void)reloadContacts {
    if (contactsRequest != nil) {
        return;
    }
    contactsRequest = [MITMobileWebAPI jsonLoadedDelegate:self];
    if (![contactsRequest requestObjectFromModule:@"emergency" command:@"contacts" parameters:nil]) {
        DLog(@"failed to fetch emergency contacts");
    }
    
    /*
    if ([self.contactsConnection isConnected]) {
        return; // a connection already exists
    }
    self.contactsConnection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    NSURL *url = [MITMobileWebAPI buildURL:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", @"contacts", @"command", nil]
								 queryBase:MITMobileWebAPIURLString];
    if ([self.contactsConnection requestDataFromURL:url]) {
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
    }
    */
}

// Receive response

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)jsonObject {
    if (request == infoRequest) {
        
        if (![jsonObject isKindOfClass:[NSArray class]]) {
            ELog(@"%@ received json result as %@, not NSArray.", NSStringFromClass([self class]), NSStringFromClass([jsonObject class]));
        } else {
            NSDictionary *response = [(NSArray *)jsonObject lastObject];
            
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
        
        infoRequest = nil;
        
    } else if (request == contactsRequest) {
        
        if (jsonObject && [jsonObject isKindOfClass:[NSArray class]]) {
            NSArray *contactsArray = (NSArray *)jsonObject;
            
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
        }
        
        contactsRequest = nil;
    }
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
    return NO;
}


- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
    // TODO: possibly retry at a later date if connection dropped or server was unavailable
    if (request == infoRequest) {
		[[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidFailToLoadNotification object:self];
        infoRequest = nil;
    } else if (request == contactsRequest) {
        contactsRequest = nil;
    }
}

@end
