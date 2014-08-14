
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class HouseVenue, RetailVenue;

@interface MITDiningPlace : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (strong, nonatomic, readonly) HouseVenue *houseVenue;
@property (strong, nonatomic, readonly) RetailVenue *retailVenue;

@property (nonatomic) NSInteger displayNumber;
@property (nonatomic, readonly, copy) NSString *title;

- (instancetype)initWithRetailVenue:(RetailVenue *)retailVenue;
- (instancetype)initWithHouseVenue:(HouseVenue *)hosueVenue;

@end