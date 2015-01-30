#import <UIKit/UIKit.h>

@interface MITNavigationController : UINavigationController

// Rotation forwarding
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;
- (NSUInteger)supportedInterfaceOrientations;
- (BOOL)shouldAutorotate;
@end
