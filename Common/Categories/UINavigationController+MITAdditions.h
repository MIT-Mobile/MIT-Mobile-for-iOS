//
//  UINavigationController+MITAdditions.h
//  MIT Mobile
//
//

#import <UIKit/UIKit.h>

@interface UINavigationController (MITAdditions)

// returning root view controller per module
- (UIViewController *)moduleRootViewController;

@end
