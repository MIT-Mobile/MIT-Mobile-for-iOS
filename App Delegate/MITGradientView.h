#import <UIKit/UIKit.h>

@interface MITGradientView : UIView
@property(nonatomic,strong) UIColor *startColor;
@property(nonatomic,strong) UIColor *endColor;
@property(nonatomic) CGRectEdge direction;
@end
