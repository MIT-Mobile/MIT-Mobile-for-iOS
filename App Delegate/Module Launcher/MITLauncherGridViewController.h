#import <UIKit/UIKit.h>

#pragma mark Forward References
@protocol MITLauncherDelegate;
@protocol MITLauncherDataSource;

#pragma mark Interfaces & Protocols
@interface MITLauncherGridViewController : UICollectionViewController
@property (nonatomic,weak) id<MITLauncherDataSource> dataSource;
@property (nonatomic,weak) id<MITLauncherDelegate> delegate;

+ (MITLauncherGridViewController*)gridLauncher;
- (instancetype)init;
@end
