#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningPlace : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (strong, nonatomic, readonly) MITDiningHouseVenue *houseVenue;
@property (strong, nonatomic, readonly) MITDiningRetailVenue *retailVenue;

@property (nonatomic) NSInteger displayNumber;
@property (nonatomic, readonly, copy) NSString *title;

- (instancetype)initWithRetailVenue:(MITDiningRetailVenue *)retailVenue;
- (instancetype)initWithHouseVenue:(MITDiningHouseVenue *)hosueVenue;

@end