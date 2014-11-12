#import "LibrariesModule.h"
#import "MITLibrariesHomeViewController.h"
#import "MITLibrariesHomeViewControllerPad.h"

@implementation LibrariesModule
- (id) init
{
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"Libraries";
        self.longName = @"Libraries";
        self.iconName = @"libraries";
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
