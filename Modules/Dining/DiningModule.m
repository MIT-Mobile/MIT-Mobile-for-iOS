#import "DiningModule.h"
#import "DiningMapListViewController.h"
#import "DiningData.h"
#import "DiningDietaryFlag.h"

#import "MITModule+Protected.h"

@implementation DiningModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag        = DiningTag;
        self.shortName  = @"Dining";
        self.longName   = @"Dining";
        self.iconName   = @"dining";
    }
    return self;
}

- (void) loadModuleHomeController
{
    DiningMapListViewController *controller = [[DiningMapListViewController alloc] init];
    self.moduleHomeController = controller;
}

@end
