#import "MIT_MobileAppDelegate.h"

@interface MIT_MobileAppDelegate (ModuleListAdditions)

#pragma mark class methods
+ (MITModule *)moduleForTag:(NSString *)aTag;

#pragma mark Basics
- (NSMutableArray *)createModules;
- (MITModule *)moduleForTabBarItem:(UITabBarItem *)item;
- (MITModule *)moduleForViewController:(UIViewController *)aViewController;
- (MITModule *)moduleForTag:(NSString *)aTag;

- (void)showModuleForTag:(NSString *)tag;

- (NSString *)activeModuleTag;

#pragma mark Preferences
- (NSArray *)defaultModuleOrder;
- (void)registerDefaultModuleOrder;
- (void)loadSavedModuleOrder;
- (void)loadActiveModule;
- (void)saveModuleOrder;
- (void)saveModulesState;

@end
