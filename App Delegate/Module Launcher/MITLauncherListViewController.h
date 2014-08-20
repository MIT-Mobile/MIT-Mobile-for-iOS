#import <UIKit/UIKit.h>

@protocol MITLauncherDelegate;
@protocol MITLauncherDataSource;

@interface MITLauncherListViewController : UITableViewController
@property (nonatomic,weak) id<MITLauncherDataSource> dataSource;
@property (nonatomic,weak) id<MITLauncherDelegate> delegate;

- (instancetype)init;
@end

@protocol MITLauncherDelegate <NSObject>
- (void)launcher:(MITLauncherListViewController*)launcher didSelectModuleAtIndexPath:(NSIndexPath*)index;
@end

@protocol MITLauncherDataSource <NSObject>
- (NSUInteger)numberOfItemsInLauncher:(MITLauncherListViewController*)launcher;
- (MITModule*)launcher:(MITLauncherListViewController*)launcher moduleAtIndexPath:(NSIndexPath*)index;
@end