
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

@class MITTiledMapView;

@interface MITDiningMapsViewController : UIViewController

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (nonatomic, weak) id<MITDiningMapsViewControllerDelegate> delegate;

- (void)setToolBarHidden:(BOOL)hidden;
- (void)updateMapWithDiningPlaces:(NSArray *)diningPlaceArray;
- (void)showDetailForRetailVenue:(MITDiningRetailVenue *)retailVenue;

@end
