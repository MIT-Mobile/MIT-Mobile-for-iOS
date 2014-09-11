
#import <UIKit/UIKit.h>

@class MITDiningRetailVenue;
@class MITDiningMapsViewController;

typedef NS_ENUM(NSUInteger, MITDiningMapsDisplayMode) {
    MITDiningMapsDisplayModeHouse,
    MITDiningMapsDisplayModeRetail,
    MITDiningMapsDisplayModeNotSet
};

@protocol MITDiningMapsViewControllerDelegate <NSObject>

- (void)popoverChangedFavoriteStatusForRetailVenue:(MITDiningRetailVenue *)retailVenue;

@end

@interface MITDiningMapsViewController : UIViewController

@property (nonatomic, weak) id<MITDiningMapsViewControllerDelegate> delegate;


- (void)updateMapWithDiningPlaces:(NSArray *)diningPlaceArray;
- (void)showDetailForRetailVenue:(MITDiningRetailVenue *)retailVenue;

@end
