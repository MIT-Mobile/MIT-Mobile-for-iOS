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


/** Returns a string formatted for display for the venue.
 This method can (and will) return nil if a valid display
 string cannot be created. The current formats this methods
 returns (in order) are:
 
 ${displayDescription}
 ${roomNumber}
 ${street}, ${city}, ${state}
 ${city}, ${state}
 
 @return A human-readable string for the location or nil if one cannot be constructed.
*/
- (NSString*)locationDisplayString;
@end
