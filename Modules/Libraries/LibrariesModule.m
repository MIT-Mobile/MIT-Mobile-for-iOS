#import "LibrariesModule.h"
#import "LibrariesViewController.h"

@implementation LibrariesModule
@dynamic rootViewController;

- (instancetype)init
{
    self = [super initWithName:MITModuleTagLibraries title:@"Libraries"];
    if (self) {
        self.imageName = @"libraries";
        self.requestQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)loadRootViewController
{
    LibrariesViewController *rootViewController = [[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil];
    self.rootViewController = rootViewController;
}

- (void)dealloc
{
    [self.requestQueue cancelAllOperations];
}

@end
