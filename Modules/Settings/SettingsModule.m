#import "SettingsModule.h"
#import "SettingsTouchstoneViewController.h"

@implementation SettingsModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagSettings title:@"Settings"];
    if (self) {
        self.imageName = MITImageSettingsModuleIcon;
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    SettingsTouchstoneViewController *rootViewController = [[SettingsTouchstoneViewController alloc] init];
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
