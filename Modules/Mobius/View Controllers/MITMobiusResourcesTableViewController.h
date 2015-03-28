#import <UIKit/UIKit.h>

@class MITMobiusResource;
@protocol MITMobiusResourcesTableViewControllerDelegate;
@protocol MITMobiusRoomDataSource;

@interface MITMobiusResourcesTableViewController : UITableViewController

@property (nonatomic,weak) id<MITMobiusRoomDataSource> dataSource;
@property(nonatomic,weak) id<MITMobiusResourcesTableViewControllerDelegate> delegate;
@property(nonatomic,readonly,weak) MITMobiusResource *selectedResource;
- (void)reloadTable;

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