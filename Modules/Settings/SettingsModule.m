#import "SettingsModule.h"

#import "MITModule.h"
#import "MITModule+Protected.h"
#import "SettingsTableViewController.h"

@implementation SettingsModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = SettingsTag;
        self.shortName = @"Settings";
        self.longName = @"Settings";
        self.iconName = @"settings";
    }
    return self;
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
}

- (BOOL)handleLocalPath:(NSString *)localPath
                  query:(NSString *)query
{
    [[MITAppDelegate() rootNavigationController] pushViewController:self.moduleHomeController
                                                           animated:YES];
	return YES;
}

@end
