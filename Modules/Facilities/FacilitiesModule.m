#import "FacilitiesModule.h"


@implementation FacilitiesModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = FacilitiesTag;
        self.shortName = @"Facilities";
        self.longName = @"Facilities";
        self.iconName = @"facilities";
        self.isMovableTab = FALSE;
        _viewController = nil;
    }
    return self;
}

- (void)dealloc {
    [_viewController release];
    [super dealloc];
}

- (UIViewController *)moduleHomeController {
    if (_viewController == nil) {
        _viewController = [[UIViewController alloc] init];
    }
    
    return _viewController;
}

@end
