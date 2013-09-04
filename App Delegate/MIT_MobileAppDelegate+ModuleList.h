#import "MIT_MobileAppDelegate.h"

@interface MIT_MobileAppDelegate (ModuleListAdditions)

#pragma mark class methods
+ (MITModule *)moduleForTag:(NSString *)aTag;

#pragma mark Basics
- (void)loadModules;
- (MITModule *)moduleForTag:(NSString *)aTag;

- (void)showModuleForTag:(NSString *)tag;

#pragma mark Preferences
- (void)saveModulesState;

@end
