#import <UIKit/UIKit.h>

@interface MITPopoverBackgroundView : UIPopoverBackgroundView {
    UIImageView *popoverArrowBubbleView;
    UIImageView *popoverBubbleView;
    UIImageView *_popoverArrowView;
    CGFloat _arrowOffset;
    UIPopoverArrowDirection _arrowDirection;
}

+ (void)setTintColor:(UIColor *)tintColor;

@end