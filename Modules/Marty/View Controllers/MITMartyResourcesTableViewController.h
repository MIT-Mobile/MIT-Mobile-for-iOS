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
@end