#import "SettingsModule.h"
#import "SettingsTableViewController.h"

@implementation SettingsModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagSettings title:@"Settings"];
    if (self) {
        self.imageName = MITImageSettingsModuleIcon;
    }

    return self;
}

- (void)loadRootViewController
{
    SettingsTableViewController *rootViewController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.rootViewController = rootViewController;
}

- (void)viewControllerDidLoad
{
    [super viewControllerDidLoad];

    self.viewController.moduleItem.type = MITModulePresentationModal;
}

- (void)didReceiveRequestWithURL:(NSURL*)url
{
    [self.navigationController popToViewController:self.rootViewController animated:NO];
}

@end
