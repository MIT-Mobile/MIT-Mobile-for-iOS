#import "MITExtendedNavBarView.h"

@implementation MITExtendedNavBarView

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    // Taken from Apple's extended nav bar example code
    
    // Use the layer shadow to draw a one pixel hairline under this view.
    [self.layer setShadowOffset:CGSizeMake(0, 1.0f/UIScreen.mainScreen.scale)];
    [self.layer setShadowRadius:0];
    
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.25f];
}

@end
