#import "MITPopoverBackgroundView.h"

#define CONTENT_INSET 0.0
#define CAP_INSET 50.0
#define ARROW_BASE 33.0
#define ARROW_HEIGHT 14.0

@interface MITPopoverBackgroundView()

@property (nonatomic, strong) UIImage *popoverBubbleImage;
@property (nonatomic, strong) UIImage *popoverArrowImage;

@end

@implementation MITPopoverBackgroundView

- (CGFloat) arrowOffset
{
    return _arrowOffset;
}

- (void) setArrowOffset:(CGFloat)arrowOffset {
    
    _arrowOffset = arrowOffset;
}

- (UIPopoverArrowDirection)arrowDirection
{
    return _arrowDirection;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection
{
    _arrowDirection = arrowDirection;
}


+(UIEdgeInsets)contentViewInsets
{
    return UIEdgeInsetsMake(CONTENT_INSET, CONTENT_INSET, CONTENT_INSET, CONTENT_INSET);
}

+ (CGFloat)arrowHeight
{
    return ARROW_HEIGHT;
}

+ (CGFloat)arrowBase
{
    return ARROW_BASE;
}

static UIColor *popoverTintColor = nil;
+ (void)setTintColor:(UIColor *)tintColor
{
    popoverTintColor = tintColor;
}

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        UIImage *popOverImage = [UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDown@2x"];
        
        popOverImage = [[UIImage alloc] initWithCGImage: popOverImage.CGImage
                                                  scale: 2
                                            orientation: UIImageOrientationUp];
        
        CGFloat popOverImageWidth = popOverImage.size.width;
        CGFloat popOverImageHeight = popOverImage.size.height;
        
        CGRect bubbleImageRect = CGRectMake(0, 0, popOverImageWidth, popOverImageHeight - ARROW_HEIGHT + 1);
        
        UIGraphicsBeginImageContextWithOptions(bubbleImageRect.size, NO, 0);
        [popOverImage drawAtPoint:CGPointZero];
        
        UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        CGRect arrowImageRect = CGRectMake((popOverImageWidth - ARROW_BASE)/2, popOverImageHeight - (ARROW_HEIGHT - 1), ARROW_BASE, ARROW_HEIGHT - 1);
        
        UIGraphicsBeginImageContextWithOptions(arrowImageRect.size, NO, 0);
        
        [popOverImage drawAtPoint:(CGPoint){-arrowImageRect.origin.x, -arrowImageRect.origin.y}];
        
        UIImage *croppedArrow = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.popoverBubbleImage = [croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(25/2, 25/2, 25/2, 25/2)];
        
        _popoverArrowBubbleView = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(25/2, 25/2, 25/2, 25/2)]];
        
        self.popoverArrowImage = croppedArrow;
        
        [self addSubview:_popoverArrowBubbleView];
        self.layer.shadowColor = [[UIColor clearColor] CGColor];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat _height = self.frame.size.height;
    CGFloat _width = self.frame.size.width;
    CGFloat _left = 0.0;
    CGFloat _top = 0.0;
    CGFloat _coordinate = 0.0;
    
    switch (self.arrowDirection) {
        case UIPopoverArrowDirectionAny:
            break;
        case UIPopoverArrowDirectionUnknown:
            break;
            
        case UIPopoverArrowDirectionUp:
            NSLog(@"UP");
            
            if (self.frame.size.width/2 + self.arrowOffset < 38 || self.frame.size.width/2 + self.arrowOffset + 38 > self.frame.size.width) {
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                _popoverArrowBubbleView.image = nil;
                
                _popoverArrowBubbleView.image = [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDownRight@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 56, 62)];
                
                NSInteger sign = 1;
                
                if (self.frame.size.width/2 + self.arrowOffset + 38 > self.frame.size.width) {
                    sign = -1;
                }
                
                CGAffineTransform scale = CGAffineTransformMakeScale(sign * .5, .5);
                CGAffineTransform transform = CGAffineTransformRotate(scale, -M_PI);
                _popoverArrowBubbleView.transform = transform;
                
                _popoverArrowBubbleView.frame =  CGRectMake(sign * (self.frame.size.width/2 + sign * (self.arrowOffset - (ARROW_BASE / 2) * sign)), 0, _width, _height);
                
            } else {
                
                _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(_popoverArrowBubbleView.frame.size.width, _popoverArrowBubbleView.frame.size.height + ARROW_HEIGHT), NO, 0);
                
                [self.popoverBubbleImage drawInRect:CGRectMake(_left, ARROW_HEIGHT, _width, _height)];
                self.popoverArrowImage = [[UIImage alloc] initWithCGImage: self.popoverArrowImage.CGImage
                                                                    scale: 1.0
                                                              orientation: UIImageOrientationDown];
                [self.popoverArrowImage drawInRect:CGRectMake(_coordinate, 0, ARROW_BASE, ARROW_HEIGHT)];
                
                _popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
            }
            break;
            
        case UIPopoverArrowDirectionDown:
            NSLog(@"Down");
            
            if (self.frame.size.width/2 + self.arrowOffset < 38 || self.frame.size.width/2 + self.arrowOffset + 38 > self.frame.size.width) {
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                _popoverArrowBubbleView.image = nil;
                
                _popoverArrowBubbleView.image = [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDownRight@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 56, 62)];
                
                NSInteger sign = -1;
                
                if (self.frame.size.width/2 + self.arrowOffset + 38 > self.frame.size.width) {
                    sign = 1;
                }
                CGAffineTransform scale = CGAffineTransformMakeScale(sign * .5, .5);
                CGAffineTransform transform = CGAffineTransformRotate(scale, 0);
                _popoverArrowBubbleView.transform = transform;
                
                sign = -sign;
                
                _popoverArrowBubbleView.frame =  CGRectMake(sign * (self.frame.size.width/2 + sign * (self.arrowOffset - (ARROW_BASE / 2) * sign)), 0, _width, _height);
                
            } else {
                
                _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(_popoverArrowBubbleView.frame.size.width, _popoverArrowBubbleView.frame.size.height + ARROW_HEIGHT), NO, 0);
                
                [self.popoverBubbleImage drawInRect:CGRectMake(_left, _top, _width, _height)];
                [self.popoverArrowImage drawInRect:CGRectMake(_coordinate, _height, ARROW_BASE, ARROW_HEIGHT)];
                
                _popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            break;
            
        case UIPopoverArrowDirectionLeft:
            NSLog(@"Left");
            
            if (self.frame.size.height/2 + self.arrowOffset < 38 || self.frame.size.height/2 + self.arrowOffset + 38 > self.frame.size.height) {
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                _popoverArrowBubbleView.image = nil;
                
                _popoverArrowBubbleView.image = [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDownRight@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 56, 62)];
                
                NSInteger sign = -1;
                
                if (self.frame.size.height/2 + self.arrowOffset + 38 > self.frame.size.height) {
                    sign = 1;
                }
                CGAffineTransform scale = CGAffineTransformMakeScale(sign * .5, .5);
                CGAffineTransform transform = CGAffineTransformRotate(scale, sign*M_PI_2);
                _popoverArrowBubbleView.transform = transform;
                
                sign = -sign;
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, sign * (self.frame.size.height/2 + sign * (self.arrowOffset - (ARROW_BASE / 2) * sign)), _width, _height);
                
            } else {
                
                _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(_popoverArrowBubbleView.frame.size.width + ARROW_HEIGHT, _popoverArrowBubbleView.frame.size.height), NO, 0);
                
                [self.popoverBubbleImage drawInRect:CGRectMake(ARROW_HEIGHT, _top, _width, _height)];
                self.popoverArrowImage = [[UIImage alloc] initWithCGImage: self.popoverArrowImage.CGImage
                                                                    scale: 1.0
                                                              orientation: UIImageOrientationRight];
                [self.popoverArrowImage drawInRect:CGRectMake(0, _coordinate, ARROW_HEIGHT, ARROW_BASE)];
                
                _popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            break;
            
        case UIPopoverArrowDirectionRight:
            NSLog(@"Right");
            
            if (self.frame.size.height/2 + self.arrowOffset < 38 || self.frame.size.height/2 + self.arrowOffset + 38 > self.frame.size.height) {
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                _popoverArrowBubbleView.image = nil;
                
                _popoverArrowBubbleView.image = [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDownRight@2x.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 56, 62)];
                
                NSInteger sign = 1;
                
                if (self.frame.size.height/2 + self.arrowOffset + 38 > self.frame.size.height) {
                    sign = -1;
                }
                CGAffineTransform scale = CGAffineTransformMakeScale(sign * .5, .5);
                CGAffineTransform transform = CGAffineTransformRotate(scale, -sign*M_PI_2);
                _popoverArrowBubbleView.transform = transform;
                
                _popoverArrowBubbleView.frame =  CGRectMake(0, sign * (self.frame.size.height/2 + sign * (self.arrowOffset - (ARROW_BASE / 2) * sign)), _width, _height);
                
            } else {
                _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
                _popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
                
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(_popoverArrowBubbleView.frame.size.width + ARROW_HEIGHT, _popoverArrowBubbleView.frame.size.height), NO, 0);
                
                [self.popoverBubbleImage drawInRect:CGRectMake(_left, _top, _width, _height)];
                self.popoverArrowImage = [[UIImage alloc] initWithCGImage: self.popoverArrowImage.CGImage
                                                                    scale: 1.0
                                                              orientation: UIImageOrientationLeft];
                [self.popoverArrowImage drawInRect:CGRectMake(_width, _coordinate, ARROW_HEIGHT, ARROW_BASE)];
                
                _popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            break;
            
    }
    if (popoverTintColor) {
        _popoverArrowBubbleView.image = [_popoverArrowBubbleView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _popoverArrowBubbleView.tintColor = popoverTintColor;
    } else {
        _popoverArrowBubbleView.image = [_popoverArrowBubbleView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _popoverArrowBubbleView.tintColor = [UIColor whiteColor];
        _popoverArrowBubbleView.alpha = .8;
    }
}

@end