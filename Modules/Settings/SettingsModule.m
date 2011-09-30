#import "SettingsModule.h"
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

- (UIViewController *)moduleHomeController {
    if (!moduleHomeController) {
        moduleHomeController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    return moduleHomeController;
}

@end
