#import <Foundation/Foundation.h>

@interface EmergencyData : NSObject
@property (nonatomic, readonly) NSString *htmlString;
@property (nonatomic, copy, readonly) NSArray *primaryPhoneNumbers;
@property (nonatomic, copy, readonly) NSArray *allPhoneNumbers;

+ (EmergencyData *)sharedData;

- (void)reloadContacts;
- (void)checkForEmergencies;

@end
