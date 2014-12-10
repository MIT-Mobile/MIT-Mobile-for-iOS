#import "DiningModule.h"
#import "MITDiningHomeViewController.h"
#import "MITDiningHomeContainerViewControllerPad.h"


@implementation DiningModule

- (instancetype)init
{
    self = [super initWithName:MITModuleTagDining title:@"Dining"];
    if (self) {
        self.imageName = MITImageDiningModuleIcon;
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;

    UIViewController *rootViewController = nil;
    switch (currentUserInterfaceIdiom) {
        case UIUserInterfaceIdiomPad:
            rootViewController = [[MITDiningHomeContainerViewControllerPad alloc] initWithNibName:nil bundle:nil];
            break;

        case UIUserInterfaceIdiomPhone:
            rootViewController = [[MITDiningHomeViewController alloc] initWithNibName:nil bundle:nil];
            break;

        default: {
            NSString *reason = [NSString stringWithFormat:@"unsupported user interface idiom %d",currentUserInterfaceIdiom];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        } break;
    }

    self.rootViewController = rootViewController;
}

@end
