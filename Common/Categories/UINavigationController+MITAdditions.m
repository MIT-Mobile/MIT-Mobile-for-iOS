//
//  UINavigationController+MITAdditions.m
//  MIT Mobile
//
//  Created by Yev Motov on 9/7/14.
//
//

#import "UINavigationController+MITAdditions.h"

@implementation UINavigationController (MITAdditions)

- (UIViewController *)moduleRootViewController
{
    UIViewController *rootVC = nil;
    
    NSArray *viewControllers = self.viewControllers;
    
    if( [viewControllers count] > 1 )
    {
        // normally the first view controller on the stack would be list of modules,
        // therefore ideally we need the second on the stack.
        rootVC = viewControllers[1];
    }
    else if( [viewControllers count] > 0 )
    {
        // shouldn't happen, but in case there's just one view controller on the stack
        // then return that one.
        rootVC = viewControllers[0];
    }
    
    return rootVC;
}

@end
