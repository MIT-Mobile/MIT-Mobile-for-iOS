#import <UIKit/UIKit.h>

@interface MITPopoverBackgroundView : UIPopoverBackgroundView {
    UIImageView *_popoverArrowBubbleView;
    CGFloat _arrowOffset;
    UIPopoverArrowDirection _arrowDirection;
}

+ (void)setTintColor:(UIColor *)tintColor;

@end