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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:duration delay:wait options:UIViewAnimationOptionAllowUserInteraction animations:^{
            viewToAnimate.alpha = 0.0;
        } completion:^(BOOL finished) {
            [viewToAnimate removeFromSuperview];
        }];
    });
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint hitPoint = [self convertPoint:point toView:self.superview];
    
    if( CGRectContainsPoint(self.frame, hitPoint) )
    {
        [self.delegate didTouchAlertView:self];
    }
    
    return [super hitTest:point withEvent:event];
}

@end
