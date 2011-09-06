#import <UIKit/UIKit.h>

@interface MITSegmentControl : UIControl
@property (nonatomic, retain) UIColor *shadowColor;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGSize titleInset;
@property (nonatomic,retain) UIFont* titleFont;
@property (nonatomic,getter = isSelected) BOOL selected;

- (id)initWithTabBarItem:(UITabBarItem*)item;

- (void)setTitle:(NSString*)title forState:(UIControlState)state;
- (void)setTitleColor:(UIColor*)titleColor forState:(UIControlState)state;
- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state;

- (NSString*)titleForState:(UIControlState)state;
- (UIColor*)titleColorForState:(UIControlState)state;
- (UIColor*)backgroundColorForState:(UIControlState)state;

@end
