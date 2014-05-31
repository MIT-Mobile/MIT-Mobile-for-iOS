//
//  MITPeopleSearchDisplayController.m
//  MIT Mobile
//
//  Created by YevDev on 5/26/14.
//
//

#import "MITPeopleSearchDisplayController.h"

@implementation MITPeopleSearchDisplayController

- (void) setActive:(BOOL)visible animated:(BOOL)animated
{
    [super setActive: visible animated: animated];
    [self.searchContentsController.navigationController setNavigationBarHidden:NO animated:NO];
    self.searchContentsController.navigationController.navigationBar.translucent = YES;
}

@end
