
#import <UIKit/UIKit.h>

@class MITDiningRetailVenue;

typedef NS_ENUM(NSUInteger, MITDiningMapsDisplayMode) {
    MITDiningMapsDisplayModeHouse,
    MITDiningMapsDisplayModeRetail,
    MITDiningMapsDisplayModeNotSet
};

@interface MITDiningMapsViewController : UIViewController

- (void)updateMapWithDiningPlaces:(NSArray *)diningPlaceArray;
- (void)showDetailForRetailVenue:(MITDiningRetailVenue *)retailVenue;

@end
