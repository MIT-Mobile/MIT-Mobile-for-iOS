#import <UIKit/UIKit.h>

#pragma mark Forward References
@class MITModule;
@protocol MITLauncherDelegate;
@protocol MITLauncherDataSource;

#pragma mark Types & Statics
typedef NS_ENUM(NSInteger, MITLauncherStyle) {
    MITLauncherStyleGrid,
    MITLauncherStyleList
};

#pragma mark Interfaces & Protocols
@interface MITLauncherViewController : UICollectionViewController
@property (nonatomic,readonly) MITLauncherStyle style;
@property (nonatomic,weak) id<MITLauncherDataSource> dataSource;
@property (nonatomic,weak) id<MITLauncherDelegate> delegate;

- (instancetype)initWithStyle:(MITLauncherStyle)style;
@end

@protocol MITLauncherDelegate <NSObject>
- (void)launcher:(MITLauncherViewController*)launcher didSelectModuleAtIndexPath:(NSIndexPath*)index;
@end

@protocol MITLauncherDataSource <NSObject>
- (NSUInteger)numberOfItemsInLauncher:(MITLauncherViewController*)launcher;
- (MITModule*)launcher:(MITLauncherViewController*)launcher moduleAtIndexPath:(NSIndexPath*)index;
@end