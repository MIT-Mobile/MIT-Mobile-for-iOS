#import <UIKit/UIKit.h>

@class MITDiningRetailVenue, MITDiningRetailVenueDetailViewController;

@protocol MITDiningRetailVenueDetailViewControllerDelegate <NSObject>

- (void)retailDetailViewController:(MITDiningRetailVenueDetailViewController *)viewController
   didUpdateFavoriteStatusForVenue:(MITDiningRetailVenue *)venue;

@optional
- (void)retailDetailViewControllerDidUpdateSize:(MITDiningRetailVenueDetailViewController *)retailDetailViewController;

@end

@interface MITDiningRetailVenueDetailViewController : UIViewController

@property (strong, nonatomic) MITDiningRetailVenue *retailVenue;
@property (weak, nonatomic) id<MITDiningRetailVenueDetailViewControllerDelegate> delegate;

/*!
 The height that the tableView will be when fully loaded.  Used to predict height before loading into view.
 */
- (CGFloat)targetTableViewHeight;

@end
