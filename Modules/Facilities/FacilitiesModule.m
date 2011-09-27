#import "FacilitiesModule.h"
#import "MITConstants.h"
#import "FacilitiesRootViewController.h"


@implementation FacilitiesModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = FacilitiesTag;
        self.shortName = @"Bldg Services";
        self.longName = @"Building Services";
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
        _viewController = [[FacilitiesRootViewController alloc] initWithNibName:@"FacilitiesRootViewController"
                                                                         bundle:nil];
    }
    
    return _viewController;
}

@end
