#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface EmergencyData : NSObject {
    NSManagedObject *info;
    NSArray *contacts;
    
    NSArray *primaryPhoneNumbers;
    NSArray *allPhoneNumbers;
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

@end
