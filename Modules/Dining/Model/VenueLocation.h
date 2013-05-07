#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HouseVenue;

@interface VenueLocation : NSManagedObject

@property (nonatomic, retain) NSString * roomNumber;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * latitude;
@property (nonatomic, retain) NSString * longitude;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSString * zipcode;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) HouseVenue *houseVenue;
@property (nonatomic, retain) NSManagedObject *retailVenue;

+ (VenueLocation *)newLocationWithDictionary:(NSDictionary *)dict;

@end
