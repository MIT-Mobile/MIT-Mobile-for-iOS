#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface EmergencyData : NSObject
@property (nonatomic, readonly) NSString *htmlString;
@property (nonatomic, readonly) NSDate *lastUpdated;
@property (nonatomic, readonly) NSDate *lastFetched;
@property (nonatomic, strong) NSDate *lastRead;
@property (nonatomic, copy, readonly) NSArray *primaryPhoneNumbers;
@property (nonatomic, copy, readonly) NSArray *allPhoneNumbers;

+ (EmergencyData *)sharedData;

- (void)fetchEmergencyInfo;
- (void)fetchContacts;

- (void)reloadContacts;
- (void)checkForEmergencies;

- (BOOL)hasNeverLoaded;
- (BOOL)didReadMessage;

@end
