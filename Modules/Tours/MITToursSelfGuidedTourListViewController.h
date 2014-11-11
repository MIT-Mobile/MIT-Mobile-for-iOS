#import <UIKit/UIKit.h>

@class MITToursTour, MITToursStop, MITToursSelfGuidedTourListViewController;

@protocol MITToursSelfGuidedTourListViewControllerDelegate <NSObject>

- (void)selfGuidedTourListViewControllerDidPressInfoButton:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController;

@optional
- (void)selfGuidedTourListViewController:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController didSelectStop:(MITToursStop *)stop;

@end

@interface MITToursSelfGuidedTourListViewController : UITableViewController

@property (nonatomic, strong) MITToursTour *tour;

@property (nonatomic, weak) id<MITToursSelfGuidedTourListViewControllerDelegate> delegate;

- (void)selectStop:(MITToursStop *)stop;
- (void)deselectStop:(MITToursStop *)stop;

@end


