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

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[FacilitiesRootViewController alloc] initWithNibName:@"FacilitiesRootViewController"
                                                                               bundle:nil];
}

@end
