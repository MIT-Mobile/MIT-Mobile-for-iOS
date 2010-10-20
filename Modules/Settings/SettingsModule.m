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
        self.isMovableTab = FALSE;
        
        SettingsTableViewController *settingsVC = [[[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        settingsVC.title = self.longName;
		
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:settingsVC]];
    }
    return self;
}

@end
