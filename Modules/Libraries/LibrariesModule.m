#import "LibrariesModule.h"
#import "LibrariesViewController.h"
#import "MITModule+Protected.h"

@implementation LibrariesModule
@synthesize requestQueue = _requestQueue;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"Libraries";
        self.longName = @"Libraries";
        self.iconName = @"libraries";
        self.requestQueue = [[[NSOperationQueue alloc] init] autorelease];
        
    }
    return self;
}

- (void) dealloc {
    self.requestQueue = nil;
    [super dealloc];
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil] autorelease];
}

@end
