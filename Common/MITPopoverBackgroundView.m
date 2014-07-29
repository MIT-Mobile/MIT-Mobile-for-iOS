#import "MITPopoverBackgroundView.h"

#define CONTENT_INSET 0.0
#define CAP_INSET 50.0
#define ARROW_BASE 31.0
#define ARROW_HEIGHT 13.0

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
        
        CGFloat popOverImageWidth = popOverImage.size.width;
        CGFloat popOverImageHeight = popOverImage.size.height;
        CGFloat arrowWidth = 74;
        
        
        UIGraphicsBeginImageContextWithOptions(CGRectMake(0, 0, popOverImageWidth, popOverImageHeight - ARROW_HEIGHT*2).size, NO, 0);
        [popOverImage drawAtPoint:(CGPoint){-CGRectMake(0, 0, popOverImageWidth, popOverImageHeight - ARROW_HEIGHT*2).origin.x, -CGRectMake(0, 0, popOverImageWidth, popOverImageHeight - ARROW_HEIGHT*2).origin.y}];
        
        UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIGraphicsBeginImageContextWithOptions(CGRectMake(popOverImageWidth/2 - arrowWidth/2, popOverImageHeight - ARROW_HEIGHT*2, arrowWidth, ARROW_HEIGHT*2).size, NO, 0);
        
        [popOverImage drawAtPoint:(CGPoint){-CGRectMake(popOverImageWidth/2 - arrowWidth/2, popOverImageHeight - ARROW_HEIGHT*2, arrowWidth, ARROW_HEIGHT*2).origin.x, -CGRectMake(popOverImageWidth/2 - arrowWidth/2, popOverImageHeight - ARROW_HEIGHT*2, arrowWidth, ARROW_HEIGHT*2).origin.y}];
        
        UIImage *croppedArrow = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        _borderImageView = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)]];
        
        _arrowView = [[UIImageView alloc] initWithImage:croppedArrow];
        
        _theBigPicture = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)]];
        
        [self addSubview:_theBigPicture];
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
            
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            _theBigPicture.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(_theBigPicture.frame.size.width, _theBigPicture.frame.size.height + ARROW_HEIGHT), NO, 0);
            
            [_borderImageView.image drawInRect:CGRectMake(_left, ARROW_HEIGHT, _width, _height)];
            _arrowView.frame = CGRectMake(_coordinate, 0, ARROW_BASE, ARROW_HEIGHT);
            _arrowView.image = [[UIImage alloc] initWithCGImage: _arrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationDown];
            [_arrowView.image drawInRect:_arrowView.frame];
            
            _theBigPicture.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
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
        _theBigPicture.image = [_theBigPicture.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _theBigPicture.tintColor = popoverTintColor;
    } else {
        _theBigPicture.image = [_theBigPicture.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _theBigPicture.tintColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:.86];
    }
}

@end

