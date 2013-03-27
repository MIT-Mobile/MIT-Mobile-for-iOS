//
//  DiningModule.m
//  MIT Mobile
//
//  Created by Austin Emmons on 3/18/13.
//
//

#import "DiningModule.h"
#import "DiningMapListViewController.h"

#import "MITModule+Protected.h"

@implementation DiningModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag        = DiningTag;
        self.shortName  = @"Dining";
        self.longName   = @"Dining";
        self.iconName   = @"news";
    }
    return self;
}

- (void) loadModuleHomeController
{
    DiningMapListViewController *controller = [[DiningMapListViewController alloc] init];
    self.moduleHomeController = controller;
}

- (void)dealloc {
    [super dealloc];
}


@end
