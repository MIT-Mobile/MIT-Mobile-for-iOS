#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import "ConnectionWrapper.h"
#import "MITMobileWebAPI.h"

@interface EmergencyData : NSObject </*ConnectionWrapperDelegate*/JSONLoadedDelegate> {
    NSManagedObject *info;
    NSArray *contacts;
    
    NSArray *primaryPhoneNumbers;
    NSArray *allPhoneNumbers;
    
    MITMobileWebAPI *infoRequest;
    MITMobileWebAPI *contactsRequest;
    //ConnectionWrapper *infoConnection;
    //ConnectionWrapper *contactsConnection;
}

+ (EmergencyData *)sharedData;

- (void)fetchEmergencyInfo;
- (void)fetchContacts;

- (void)reloadContacts;
- (void)checkForEmergencies;

- (BOOL)hasNeverLoaded;
- (BOOL)didReadMessage;

@property (nonatomic, readonly) NSString *htmlString;
@property (nonatomic, readonly) NSDate *lastUpdated;
@property (nonatomic, readonly) NSDate *lastFetched;
@property (nonatomic, retain) NSDate *lastRead;
@property (nonatomic, readonly) NSArray *primaryPhoneNumbers;
@property (nonatomic, readonly) NSArray *allPhoneNumbers;
@property (retain) ConnectionWrapper *infoConnection;
@property (retain) ConnectionWrapper *contactsConnection;

@end
