#import "KIFUITestActor+Navigation.h"

@implementation KIFUITestActor (Navigation)

- (void)navigateToModuleWithName:(NSString *)name {
    [self tapViewWithAccessibilityLabel:MITAccessibilityMainNavigationButtonLabel];
    [self tapViewWithAccessibilityLabel:name];
}

@end
