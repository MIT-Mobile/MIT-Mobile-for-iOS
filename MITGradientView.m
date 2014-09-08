#import "MITGradientView.h"

@interface MITGradientView ()
@property(nonatomic,strong) UIColor *startColor;
@property(nonatomic,strong) UIColor *endColor;

@property(nonatomic,weak) CAGradientLayer *gradientLayer;
@property(nonatomic,readonly) BOOL needsGradientLayerUpdate;

- (void)updateGradientIfNeeded;
- (void)setNeedsGradientUpdate;
@end

@implementation MITGradientView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.startColor = [UIColor whiteColor];
        self.endColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    if (newSuperview) {
        [self updateGradient];
    }
}

- (void)updateGradient
{
    if (_needsGradientLayerUpdate) {
        if (!self.gradientLayer) {
            CAGradientLayer *layer = [[CAGradientLayer alloc] init];
            [self.layer addSublayer:layer];
            self.gradientLayer = layer;
        }

        self.gradientLayer.colors = @[(__bridge id)[self.startColor CGColor], (__bridge id)[self.endColor CGColor]];
        self.gradientLayer.startPoint = CGPointMake(1, 0.5);
        self.gradientLayer.endPoint = CGPointMake(0, 0.5);
    }
}
@end
