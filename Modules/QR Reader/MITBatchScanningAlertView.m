//
//  MITBatchScanningAlertView.m
//  MIT Mobile
//
//  Created by Yev Motov on 12/6/14.
//
//

#import "MITBatchScanningAlertView.h"

@interface MITBatchScanningAlertView()

@end

@implementation MITBatchScanningAlertView

- (void)awakeFromNib
{
    [self.layer setCornerRadius:5];
    
    CGRect frame = self.frame;
    frame.origin.x = [UIScreen mainScreen].bounds.size.width - frame.size.width - 10;
    frame.origin.y = 60;
    
    self.frame = frame;
}

- (void)fadeOutWithDuration:(NSTimeInterval)duration andWait:(NSTimeInterval)wait
{
    __block UIView *viewToAnimate = self;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:duration animations:^{
            viewToAnimate.alpha = 0.0;
        } completion:^(BOOL finished) {
            [viewToAnimate removeFromSuperview];
        }];
    });
}

@end
