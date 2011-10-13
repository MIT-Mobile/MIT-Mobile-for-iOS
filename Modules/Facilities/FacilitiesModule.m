#import "FacilitiesModule.h"
#import "MITConstants.h"
#import "FacilitiesRootViewController.h"

#import "MITModule+Protected.h"

@implementation FacilitiesModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = FacilitiesTag;
        self.shortName = @"Bldg Services";
        self.longName = @"Building Services";
        self.iconName = @"facilities";
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)loadModuleHomeController
{
    FacilitiesRootViewController *controller = [[FacilitiesRootViewController alloc] initWithNibName:@"FacilitiesRootViewController"
                                                                                              bundle:nil];
    self.moduleHomeController = [controller autorelease];
}

@end
