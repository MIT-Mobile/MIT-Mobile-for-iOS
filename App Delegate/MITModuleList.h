#import "MIT_MobileAppDelegate.h"

@interface MIT_MobileAppDelegate (ModuleListAdditions)

#pragma mark Basics
- (NSMutableArray *)createModules;
- (MITModule *)moduleForTabBarItem:(UITabBarItem *)item;
- (MITModule *)moduleForViewController:(UIViewController *)aViewController;
- (MITModule *)moduleForTag:(NSString *)aTag;

- (void)showModuleForTag:(NSString *)tag;

- (NSString *)activeModuleTag;

#pragma mark Preferences
- (void)registerDefaultModuleOrder;
- (void)loadSavedModuleOrder;
- (void)loadActiveModule;
- (void)saveModuleOrder;

@end
