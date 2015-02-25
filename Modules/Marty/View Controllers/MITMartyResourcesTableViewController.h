#import <UIKit/UIKit.h>

@class MITMartyResource;
@protocol MITMartyResourcesTableViewControllerDelegate;

@interface MITMartyResourcesTableViewController : UITableViewController
@property(nonatomic,weak) id<MITMartyResourcesTableViewControllerDelegate> delegate;
@property(nonatomic,copy) NSArray *resources;
@property(nonatomic,readonly,weak) MITMartyResource *selectedResource;

@end

@protocol MITMartyResourcesTableViewControllerDelegate <NSObject>
@required
- (void)resourcesTableViewController:(MITMartyResourcesTableViewController*)tableViewController didSelectResource:(MITMartyResource*)resource;

@optional
- (void)resourcesTableViewControllerDidSelectPlaceholderCell:(MITMartyResourcesTableViewController*)tableViewController;
- (void)resourcesTableViewController:(MITMartyResourcesTableViewController*)tableViewController didScrollToContentOffset:(CGPoint)contentOffset;
- (BOOL)shouldDisplayPlaceholderCellForResourcesTableViewController:(MITMartyResourcesTableViewController*)tableViewController;
- (CGFloat)heightOfPlaceholderCellForResourcesTableViewController:(MITMartyResourcesTableViewController*)tableViewController;
@end