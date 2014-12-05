#import "LibrariesModule.h"
#import "MITLibrariesHomeViewController.h"
#import "MITLibrariesHomeViewControllerPad.h"

@implementation LibrariesModule
@dynamic rootViewController;

- (instancetype)init
{
    self = [super initWithName:MITModuleTagLibraries title:@"Libraries"];
    if (self) {
        self.imageName = MITImageLibrariesModuleIcon;
        self.requestQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

//- (void) dealloc
//{
//    [self.requestQueue cancelAllOperations];
//}
//
//- (void)loadModuleHomeController
//{
//    self.moduleHomeController = [[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil];
//}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIViewController *rootViewController = nil;
    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    
    if (UIUserInterfaceIdiomPad == userInterfaceIdiom) {
        rootViewController = [[MITLibrariesHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
    } else if (UIUserInterfaceIdiomPhone == userInterfaceIdiom) {
        rootViewController = [[MITLibrariesHomeViewController alloc] initWithNibName:nil bundle:nil];
    }
    
    self.rootViewController = rootViewController;
}

@end
