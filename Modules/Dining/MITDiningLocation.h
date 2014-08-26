#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningLocation : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * latitude;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * longitude;
@property (nonatomic, retain) NSString * mitRoomNumber;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * zipCode;
@property (nonatomic, retain) MITDiningHouseVenue *houseVenue;
@property (nonatomic, retain) MITDiningRetailVenue *retailVenue;

- (NSString *)locationDisplayString;

@end
