
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class HouseVenue, RetailVenue;

@interface MITDiningPlace : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (strong, nonatomic, readonly) HouseVenue *houseVenue;
@property (strong, nonatomic, readonly) RetailVenue *retailVenue;

@property (nonatomic) NSInteger displayNumber;

- (instancetype)initWithRetailVenue:(RetailVenue *)retailVenue;
- (instancetype)initWithHouseVenue:(HouseVenue *)hosueVenue;

@property (nonatomic, readonly) NSString *title;

@end
