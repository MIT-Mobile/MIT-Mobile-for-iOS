#import <Foundation/Foundation.h>

@class MITModule;

@protocol MITLauncherDelegate <NSObject>
- (void)launcher:(UIViewController*)launcher didSelectModuleAtIndexPath:(NSIndexPath*)index;
@end

@protocol MITLauncherDataSource <NSObject>
- (NSUInteger)numberOfItemsInLauncher:(UIViewController*)launcher;
- (MITModule*)launcher:(UIViewController*)launcher moduleAtIndexPath:(NSIndexPath*)index;
@end
