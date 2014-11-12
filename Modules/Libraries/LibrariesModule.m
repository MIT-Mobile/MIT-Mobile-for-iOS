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

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITLibrariesHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITLibrariesHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
}

@end
