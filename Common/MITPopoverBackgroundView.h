#import <UIKit/UIKit.h>

@interface MITPopoverBackgroundView : UIPopoverBackgroundView {
    UIImageView *_theBigPicture;
    UIImageView *_borderImageView;
    UIImageView *_arrowView;
    CGFloat _arrowOffset;
    UIPopoverArrowDirection _arrowDirection;
}

+ (void)setTintColor:(UIColor *)tintColor;

@end