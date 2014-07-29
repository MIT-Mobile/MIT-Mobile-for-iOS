#import "MITPopoverBackgroundView.h"
#import "UIImage+Resize.h"
#define CONTENT_INSET 0.0
#define CAP_INSET 50.0
#define ARROW_BASE 31.0
#define ARROW_HEIGHT 13.0

@implementation MITPopoverBackgroundView

- (CGFloat) arrowOffset {
    return _arrowOffset;
}

- (void) setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
}

- (UIPopoverArrowDirection)arrowDirection {
    return _arrowDirection;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
}


+(UIEdgeInsets)contentViewInsets{
    return UIEdgeInsetsMake(CONTENT_INSET, CONTENT_INSET, CONTENT_INSET, CONTENT_INSET);
}

+(CGFloat)arrowHeight{
    return ARROW_HEIGHT;
}

+(CGFloat)arrowBase{
    return ARROW_BASE;
}

static UIColor *popoverTintColor = nil;
+ (void)setTintColor:(UIColor *)tintColor
{
    popoverTintColor = tintColor;
}

-(id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        UIGraphicsBeginImageContextWithOptions(CGRectMake(0, 0, 174, 104-26).size, NO, 1);
        [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDown@2x"]  drawAtPoint:(CGPoint){-CGRectMake(0, 0, 174, 104-26).origin.x, -CGRectMake(0, 0, 174, 104-26).origin.y}];
        UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIGraphicsBeginImageContextWithOptions(CGRectMake(172/2-76/2, 104-26, 76, 26).size, NO, 1);
        [[UIImage imageNamed:@"_UIPopoverViewBlurMaskBackgroundArrowDown@2x"]  drawAtPoint:(CGPoint){-CGRectMake(172/2-76/2, 104-26, 76, 26).origin.x, -CGRectMake(172/2-76/2, 104-26, 76, 26).origin.y}];
        UIImage *croppedArrow = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        _borderImageView = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)]];
        
        _arrowView = [[UIImageView alloc] initWithImage:croppedArrow];
        
        [self addSubview:_borderImageView];
        //[self addSubview:_arrowView];
        self.layer.shadowColor = [[UIColor clearColor] CGColor];
        
    }
    return self;
}

-  (void)layoutSubviews {
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
            
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            
            _borderImageView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(_borderImageView.frame.size.width, _borderImageView.frame.size.height + ARROW_HEIGHT), NO, 0);
            [_borderImageView.image drawInRect:CGRectMake(_left, ARROW_HEIGHT, _width, _height)];
            
            _arrowView.frame = CGRectMake(_coordinate, 0, ARROW_BASE, ARROW_HEIGHT);
            
            _arrowView.image = [[UIImage alloc] initWithCGImage: _arrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationDown];
            
            [_arrowView.image drawInRect:_arrowView.frame];
            
            _borderImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            _borderImageView.image = [_borderImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            break;
            
        case UIPopoverArrowDirectionDown:
            NSLog(@"Down");
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            
            _borderImageView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(_borderImageView.frame.size.width, _borderImageView.frame.size.height + ARROW_HEIGHT), NO, 0);
            [_borderImageView.image drawInRect:CGRectMake(_left, _top, _width, _height)];
            _arrowView.frame = CGRectMake(_coordinate, _height, ARROW_BASE, ARROW_HEIGHT);
            
            [_arrowView.image drawInRect:_arrowView.frame];
            
            _borderImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
        case UIPopoverArrowDirectionLeft:
            NSLog(@"Left");
            
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            
            _borderImageView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(_borderImageView.frame.size.width + ARROW_HEIGHT, _borderImageView.frame.size.height), NO, 0);
            [_borderImageView.image drawInRect:CGRectMake(ARROW_HEIGHT, _top, _width, _height)];
            _arrowView.frame = CGRectMake(0, _coordinate, ARROW_HEIGHT, ARROW_BASE);
            
            _arrowView.image = [[UIImage alloc] initWithCGImage: _arrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationRight];
            
            [_arrowView.image drawInRect:_arrowView.frame];
            
            _borderImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
        case UIPopoverArrowDirectionRight:
            NSLog(@"Right");
            
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            
            _borderImageView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(_borderImageView.frame.size.width + ARROW_HEIGHT, _borderImageView.frame.size.height), NO, 0);
            [_borderImageView.image drawInRect:CGRectMake(_left, _top, _width, _height)];
            _arrowView.frame = CGRectMake(_width, _coordinate, ARROW_HEIGHT, ARROW_BASE);
            
            _arrowView.image = [[UIImage alloc] initWithCGImage: _arrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationLeft];
            
            [_arrowView.image drawInRect:_arrowView.frame];
            
            _borderImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
    }
    if (popoverTintColor) {
        _borderImageView.image = [_borderImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _borderImageView.tintColor = popoverTintColor;
    }
}

@end

