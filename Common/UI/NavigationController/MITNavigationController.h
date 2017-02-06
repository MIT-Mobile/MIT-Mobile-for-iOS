#import <UIKit/UIKit.h>

@interface MITNavigationController : UINavigationController

// Rotation forwarding
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;
- (UIInterfaceOrientationMask)supportedInterfaceOrientations;
- (BOOL)shouldAutorotate;
@end
