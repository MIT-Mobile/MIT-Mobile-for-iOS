#import <UIKit/UIKit.h>

@class MITToursTour;
@class MITToursStop;
@protocol MITToursSelfGuidedTourListViewControllerDelegate;

@interface MITToursSelfGuidedTourListViewController : UITableViewController

@property (nonatomic, strong) MITToursTour *tour;

@property (nonatomic, weak) id<MITToursSelfGuidedTourListViewControllerDelegate> delegate;

@end

@protocol MITToursSelfGuidedTourListViewControllerDelegate <NSObject>

@optional
- (void)selfGuidedTourListViewController:(MITToursSelfGuidedTourListViewController *)selfGuidedTourListViewController didSelectStop:(MITToursStop *)stop;

@end
