#import <Foundation/Foundation.h>

@interface EmergencyData : NSObject
@property (nonatomic, readonly) NSString *htmlString;
@property (nonatomic, copy, readonly) NSDictionary *campusPolicePhoneNumber;
@property (nonatomic, copy, readonly) NSDictionary *medicalPhoneNumber;
@property (nonatomic, copy, readonly) NSDictionary *emergencyResponseGuideLink;
@property (nonatomic, copy, readonly) NSDictionary *emergencyStatusPhoneNumber;
@property (nonatomic, copy, readonly) NSArray *primaryItems;
@property (nonatomic, copy, readonly) NSArray *allPhoneNumbers;

+ (EmergencyData *)sharedData;

- (void)reloadContacts;
- (void)checkForEmergencies;

@end
