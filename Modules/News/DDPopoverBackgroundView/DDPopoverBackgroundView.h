//
// DDPopoverBackgroundView.h
// https://github.com/ddebin/DDPopoverBackgroundView
//

#ifndef __IPHONE_5_0
#warning "This project uses features only available in iOS SDK 5.0 and later."
#endif

#import <UIKit/UIKit.h>
#import <UIKit/UIPopoverBackgroundView.h>


@interface DDPopoverBackgroundView : UIPopoverBackgroundView
{
	CGFloat						arrowOffset;
	UIPopoverArrowDirection		arrowDirection;
	UIImageView					*arrowImageView;
	UIImageView					*popoverBackgroundImageView;
}

@property (nonatomic, readwrite) CGFloat arrowOffset;
@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;

// adjust content inset (~ border width)
+ (void)setContentInset:(CGFloat)contentInset;

// set tint color used for arrow and popover background
+ (void)setTintColor:(UIColor *)tintColor;

// enable/disable shadow under popover
+ (void)setShadowEnabled:(BOOL)shadowEnabled;

// set arrow width (base) / height
+ (void)setArrowBase:(CGFloat)arrowBase;
+ (void)setArrowHeight:(CGFloat)arrowHeight;

// set custom images for background and top/right/bottom/left arrows
+ (void)setBackgroundImage:(UIImage *)background top:(UIImage *)top right:(UIImage *)right bottom:(UIImage *)bottom left:(UIImage *)left;

// rebuild pre-rendered arrow/background images
+ (void)rebuildArrowImages;

@end
