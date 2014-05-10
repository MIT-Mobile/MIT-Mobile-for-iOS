#import "LibrariesModule.h"
#import "LibrariesViewController.h"


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

- (void) dealloc
{
    [self.requestQueue cancelAllOperations];
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil];
}

@end
