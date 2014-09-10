#import "MITGradientView.h"

@interface MITGradientView ()
@property(nonatomic,weak) CAGradientLayer *gradientLayer;

@end

@implementation MITGradientView
@synthesize endColor = _endColor;
@synthesize startColor = _startColor;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
    }

    return self;
}

- (void)setDirection:(CGRectEdge)direction
{
    if (_direction != direction) {
        _direction = direction;
        [self _updateGradient];
    }
}

- (UIColor*)startColor
{
    if (!_startColor) {
        _startColor = [UIColor whiteColor];
    }
    
    return _startColor;
}

- (void)setStartColor:(UIColor *)startColor
{
    if (![_startColor isEqual:startColor]) {
        _startColor = startColor;
        [self _updateGradient];
    }
}

- (UIColor*)endColor
{
    if (!_endColor) {
        _endColor = [UIColor clearColor];
    }
    
    return _endColor;
}

- (void)setEndColor:(UIColor *)endColor
{
    if (![_endColor isEqual:endColor]) {
        _endColor = endColor;
        [self _updateGradient];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    if (newSuperview) {
        [self _updateGradient];
    }
}

- (void)_updateGradient
{
    if (!self.gradientLayer) {
        CAGradientLayer *layer = [[CAGradientLayer alloc] init];
        [self.layer addSublayer:layer];
        self.layer.mask = layer;
        self.gradientLayer = layer;
    }
    
    self.gradientLayer.frame = self.layer.bounds;
    self.gradientLayer.colors = @[(__bridge id)[self.startColor CGColor], (__bridge id)[self.endColor CGColor]];
    
    CGPoint startPoint = CGPointZero;
    CGPoint endPoint = CGPointZero;
    
    switch (self.direction) {
        case CGRectMinXEdge: {
            startPoint = CGPointMake(0, 0.5);
            endPoint = CGPointMake(1, 0.5);
        } break;
            
        case CGRectMinYEdge: {
            startPoint = CGPointMake(0, 0);
            endPoint = CGPointMake(0, 1);
        } break;
            
        case CGRectMaxYEdge: {
            startPoint = CGPointMake(0, 1);
            endPoint = CGPointMake(0, 0);
        } break;
            
        case CGRectMaxXEdge: {
            startPoint = CGPointMake(1, 0.5);
            endPoint = CGPointMake(0, 0.5);
        } break;
    }
    
    self.gradientLayer.startPoint = startPoint;
    self.gradientLayer.endPoint = endPoint;
    
    [self.gradientLayer setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

@end
