#import "LibrariesModule.h"
#import "LibrariesViewController.h"


@implementation LibrariesModule
@synthesize requestQueue;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"Libraries";
        self.longName = @"Libraries";
        self.iconName = @"libraries";
        self.isMovableTab = TRUE;
        self.requestQueue = [[[NSOperationQueue alloc] init] autorelease];
        
    }
    return self;
}

- (void) dealloc {
    self.requestQueue = nil;
    [super dealloc];
}

- (UIViewController *)moduleHomeController {
    if (!moduleHomeController) {
        moduleHomeController = [[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil];
    }
    return moduleHomeController;
}
@end
