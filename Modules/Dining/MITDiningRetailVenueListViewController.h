#import "MITDiningRefreshDataProtocols.h"
#import <UIKit/UIKit.h>

@class MITDiningRetailVenueListViewController, MITDiningRetailVenue, MITDiningRetailVenueDataManager;

@protocol MITDiningRetailVenueListViewControllerDelegate <NSObject>

- (void)retailVenueListViewController:(MITDiningRetailVenueListViewController *)listViewController didSelectVenue:(MITDiningRetailVenue *)venue;

@end

@interface MITDiningRetailVenueListViewController : UITableViewController

@property (nonatomic, weak) id<MITDiningRetailVenueListViewControllerDelegate> delegate;
@property (nonatomic, weak) id<MITDiningRefreshRequestDelegate>refreshDelegate;

@property (nonatomic, strong) NSArray *retailVenues;
@property (nonatomic, strong) MITDiningRetailVenueDataManager *dataManager;


@end
