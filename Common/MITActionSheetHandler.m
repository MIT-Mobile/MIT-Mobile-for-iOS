//
//  MITActionSheetHandler.m
//  MIT Mobile
//
//

#import "MITActionSheetHandler.h"
#import "UIKit+MITAdditions.h"

@implementation MITActionSheetHandler

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( self.delegateBlock )
    {
        self.delegateBlock(actionSheet, buttonIndex);
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:self.actionSheetTintColor forState:UIControlStateNormal];
        }
    }
}

@end
