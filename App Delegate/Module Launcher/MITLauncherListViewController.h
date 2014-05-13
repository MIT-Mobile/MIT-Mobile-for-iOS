#import <UIKit/UIKit.h>

@protocol MITLauncherDelegate;
@protocol MITLauncherDataSource;

@interface MITLauncherListViewController : UITableViewController
@property (nonatomic,weak) id<MITLauncherDataSource> dataSource;
@property (nonatomic,weak) id<MITLauncherDelegate> delegate;

- (instancetype)init;
@end
