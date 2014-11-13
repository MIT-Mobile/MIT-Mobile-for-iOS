#import "ToursModule.h"
#import "MITModule.h"
#import "MITToursHomeViewController.h"
#import "MITToursHomeViewControllerPad.h"

@implementation ToursModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = ToursTag;
        self.shortName = @"Tours";
        self.longName = @"Campus Tour";
        self.iconName = @"tours";
    }
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITToursHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITToursHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
}

@end
