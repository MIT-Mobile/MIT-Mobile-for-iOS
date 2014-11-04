#import <UIKit/UIKit.h>

//The images used in MITPopoverBackgroundView.m are the property of Apple Inc. and are not covered by this project's license.
//They were obtained using the iOS Artwork Extractor, https://github.com/0xced/iOS-Artwork-Extractor.
 
@interface MITPopoverBackgroundView : UIPopoverBackgroundView {
    UIImageView *_popoverArrowBubbleView;
    CGFloat _arrowOffset;
    UIPopoverArrowDirection _arrowDirection;
}

+ (void)setTintColor:(UIColor *)tintColor;

@end