#import "LinksModule.h"
#import "LinksViewController.h"

@implementation LinksModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagLinks title:@"Links"];
    if (self) {
        self.imageName = MITImageLinksModuleIcon;
    }
    
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    LinksViewController *rootViewController = [[LinksViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.rootViewController = rootViewController;
}

#pragma mark URL Request handling
- (void)didReceiveRequestWithURL:(NSURL*)url
{
    [super didReceiveRequestWithURL:url];
    [self.navigationController popToViewController:self.rootViewController animated:NO];
}

- (void)viewControllerDidLoad
{
    [super viewControllerDidLoad];
    
    self.viewController.moduleItem.type = MITModulePresentationModal;
}

@end