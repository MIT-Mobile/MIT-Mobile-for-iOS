//
//  KIFUITestActor+Navigation.m
//  MIT Mobile
//
//  Created by Logan Wright on 2/3/15.
//
//

#import "KIFUITestActor+Navigation.h"

@implementation KIFUITestActor (Navigation)

- (void)navigateToModuleWithName:(NSString *)name {
    [self tapViewWithAccessibilityLabel:@"Main Navigation Button"];
    [self tapViewWithAccessibilityLabel:name];
}

- (void)blah {
}

@end
