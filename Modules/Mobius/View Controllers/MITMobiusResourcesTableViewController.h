#import <UIKit/UIKit.h>

@class MITMobiusResource;
@protocol MITMobiusResourcesTableViewControllerDelegate;

@interface MITMobiusResourcesTableViewController : UITableViewController
@property(nonatomic,weak) id<MITMobiusResourcesTableViewControllerDelegate> delegate;
@property(nonatomic,readonly,weak) MITMobiusResource *selectedResource;
- (void)setBuildingSections:(NSArray *)buildingSections setResourcesByBuilding:(NSDictionary *)resourcesByBuilding;

@end

@protocol MITMobiusResourcesTableViewControllerDelegate <NSObject>
@required
- (void)resourcesTableViewController:(MITMobiusResourcesTableViewController*)tableViewController didSelectResource:(MITMobiusResource*)resource;

@optional
- (void)resourcesTableViewControllerDidSelectPlaceholderCell:(MITMobiusResourcesTableViewController*)tableViewController;
- (void)resourcesTableViewController:(MITMobiusResourcesTableViewController*)tableViewController didScrollToContentOffset:(CGPoint)contentOffset;
- (BOOL)shouldDisplayPlaceholderCellForResourcesTableViewController:(MITMobiusResourcesTableViewController*)tableViewController;
- (CGFloat)heightOfPlaceholderCellForResourcesTableViewController:(MITMobiusResourcesTableViewController*)tableViewController;
@end