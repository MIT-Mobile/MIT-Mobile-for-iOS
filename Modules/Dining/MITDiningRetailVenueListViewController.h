#import <UIKit/UIKit.h>

@class MITDiningRetailVenueListViewController;
@class MITDiningRetailVenue;

@protocol MITDiningRetailVenueListViewControllerDelegate <NSObject>

- (void)retailVenueListViewController:(MITDiningRetailVenueListViewController *)listViewController didSelectVenue:(MITDiningRetailVenue *)venue;

@end

@interface MITDiningRetailVenueListViewController : UITableViewController

@property (nonatomic, weak) id<MITDiningRetailVenueListViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *retailVenues;

@end
