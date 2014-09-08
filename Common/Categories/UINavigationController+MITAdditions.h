//
//  UINavigationController+MITAdditions.h
//  MIT Mobile
//
//  Created by Yev Motov on 9/7/14.
//
//

#import <UIKit/UIKit.h>

@interface UINavigationController (MITAdditions)

// returning root view controller per module
- (UIViewController *)moduleRootViewController;

@end
