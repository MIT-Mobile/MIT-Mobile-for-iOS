#import "LibrariesModule.h"
#import "LibrariesViewController.h"


@implementation LibrariesModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"Libraries";
        self.longName = @"Libraries";
        self.iconName = @"about";
        self.isMovableTab = TRUE;
        
    }
    return self;
}

- (UIViewController *)moduleHomeController {
    if (!moduleHomeController) {
        moduleHomeController = [[LibrariesViewController alloc] initWithNibName:@"LibrariesViewController" bundle:nil];
    }
    return moduleHomeController;
}
@end
