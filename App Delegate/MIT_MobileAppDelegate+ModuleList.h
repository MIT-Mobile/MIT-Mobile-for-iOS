#import "MIT_MobileAppDelegate.h"

@interface MIT_MobileAppDelegate (ModuleListAdditions)

#pragma mark class methods
+ (MITModule *)moduleForTag:(NSString *)aTag;

#pragma mark Basics
- (NSMutableArray *)createModules;
- (MITModule *)moduleForTag:(NSString *)aTag;

- (void)showModuleForTag:(NSString *)tag;

#pragma mark Preferences
- (NSArray *)defaultModuleOrder;
- (void)registerDefaultModuleOrder;
- (void)loadSavedModuleOrder;
- (void)saveModulesState;

@end
