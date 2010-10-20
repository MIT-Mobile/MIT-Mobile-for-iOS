#import "EmergencyData.h"
#import "MITJSON.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "MITMobileWebAPI.h"

@implementation EmergencyData

@synthesize primaryPhoneNumbers, allPhoneNumbers, infoConnection, contactsConnection;

@dynamic htmlString, lastUpdated, lastFetched;

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

- (void)release {
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
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES] autorelease];
    allPhoneNumbers = [[CoreDataManager objectsForEntity:EmergencyContactEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:sortDescriptor]] retain];
    if (!allPhoneNumbers) {
        allPhoneNumbers = [[NSArray alloc] init];
    }
}


#pragma mark -
#pragma mark Accessors

- (NSDate *)lastUpdated {
    return [info valueForKey:@"lastUpdated"];
}

- (NSDate *)lastFetched {
    return [info valueForKey:@"lastFetched"];
}

- (NSString *)htmlString {
    NSDate *lastUpdated = [info valueForKey:@"lastUpdated"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/y h:m a zz"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *lastUpdatedString = [formatter stringFromDate:lastUpdated];
    [formatter release];
    
    NSString *htmlString = [NSString stringWithFormat:
                            @"<html>"
                            "<head>"
                            "<style type=\"text/css\" media=\"screen\">"
                            "body { margin: 0; padding: 0; overflow: hidden; font-family: Helvetica; font-size: 17px; }"
                            "a { color: #990000; }"
                            ".stamp { font-size: 14px; }"
                            "</style>"
                            "</head>"
                            "<body>"
                            "<div id=\"something_unique\">"
                            "%@"
                            "<p class=\"stamp\">Posted %@</p>"
                            "</div>"
                            "</body>"
                            "</html>",
                            [info valueForKey:@"htmlString"], lastUpdatedString];
    
    
    return htmlString;
}

#pragma mark -
#pragma mark Asynchronous HTTP - preferred

// Send request
- (void)checkForEmergencies {
    if ([self.infoConnection isConnected]) {
        return; // a connection already exists
    }
    // TODO: use Reachability to wait until app gets a connection to perform check
    self.infoConnection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    NSURL *url = [MITMobileWebAPI buildQuery:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", nil]
                                   queryBase:MITMobileWebAPIURLString];
    BOOL dispatchedSuccessfully = [infoConnection requestDataFromURL:url];
    if (dispatchedSuccessfully) {
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
    }
}

// request contacts
- (void)reloadContacts {
    if ([self.contactsConnection isConnected]) {
        return; // a connection already exists
    }
    self.contactsConnection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    NSURL *url = [MITMobileWebAPI buildQuery:[NSDictionary dictionaryWithObjectsAndKeys:@"emergency", @"module", @"contacts", @"command", nil]
                                   queryBase:MITMobileWebAPIURLString];
    if ([self.contactsConnection requestDataFromURL:url]) {
        [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
    }
}

// Receive response
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    if (wrapper == infoConnection) {
        self.infoConnection = nil;
        id jsonObject = [MITJSON objectWithJSONData:data];
        NSDictionary *response = nil;
        
        if (![jsonObject isKindOfClass:[NSArray class]]) {
            NSLog(@"%@ received json result as %@, not NSArray.", NSStringFromClass([self class]), NSStringFromClass([jsonObject class]));
        } else {
            response = [(NSArray *)jsonObject lastObject];
            
            NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:[[response objectForKey:@"unixtime"] doubleValue]];
            NSDate *previouslyUpdated = [info valueForKey:@"lastUpdated"];
            
            if (!previouslyUpdated || [lastUpdated timeIntervalSinceDate:previouslyUpdated] > 0) {
                [info setValue:lastUpdated forKey:@"lastUpdated"];
                [info setValue:[NSDate date] forKey:@"lastFetched"];
                [info setValue:[response objectForKey:@"text"] forKey:@"htmlString"];
                [CoreDataManager saveData];
                
                [self fetchEmergencyInfo];
                // notify listeners that this is a new emergency
                [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidChangeNotification object:self];
            }
            // notify listeners that the info is done loading, regardless of whether it's changed
            [[NSNotificationCenter defaultCenter] postNotificationName:EmergencyInfoDidLoadNotification object:self];
        }
    } else if (wrapper == contactsConnection) {
        self.contactsConnection = nil;
        id jsonObject = [MITJSON objectWithJSONData:data];
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
    }
    
    
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    // TODO: possibly retry at a later date if connection dropped or server was unavailable
    if (wrapper == infoConnection) {
        self.infoConnection = nil;
    } else if (wrapper == contactsConnection) {
        self.contactsConnection = nil;
    }
}

#pragma mark -
#pragma mark Synchronous HTTP - less preferred

- (NSString *)stringWithUrl:(NSURL *)url
{
    NSString *result;
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:30];
    // Fetch the JSON response
	NSData *urlData;
	NSURLResponse *response;
	NSError *error;
    
	// Make synchronous request
	urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    
 	// Construct a String around the Data from the response
    result = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
	return [result autorelease];
}

@end
