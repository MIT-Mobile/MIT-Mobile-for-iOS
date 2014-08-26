#import "DiningModule.h"
//#import "DiningMapListViewController.h"
//#import "DiningData.h"
//#import "DiningDietaryFlag.h"
#import "MITDiningHomeViewController.h"
#import "MITDiningHomeViewControllerPad.h"


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

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITDiningHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITDiningHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
}

@end
