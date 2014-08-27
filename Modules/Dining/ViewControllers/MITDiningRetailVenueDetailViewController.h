#import <UIKit/UIKit.h>

@class MITDiningRetailVenue, MITDiningRetailVenueDetailViewController;

@protocol MITDiningRetailVenueDetailViewControllerDelegate <NSObject>

- (void)retailDetailViewController:(MITDiningRetailVenueDetailViewController *)viewController
   didUpdateFavoriteStatusForVenue:(MITDiningRetailVenue *)venue;

@end

@interface MITDiningRetailVenueDetailViewController : UIViewController

@property (strong, nonatomic) MITDiningRetailVenue *retailVenue;
@property (weak, nonatomic) id<MITDiningRetailVenueDetailViewControllerDelegate> delegate;

@end
