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
        
        popoverBubbleView = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)]];
        
        popoverArrowBubbleView = [[UIImageView alloc] initWithImage:[croppedImage resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30)]];
        
        _popoverArrowView = [[UIImageView alloc] initWithImage:croppedArrow];
        
        [self addSubview:popoverArrowBubbleView];
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
            popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(popoverArrowBubbleView.frame.size.width, popoverArrowBubbleView.frame.size.height + ARROW_HEIGHT), NO, 0);
            
            [popoverBubbleView.image drawInRect:CGRectMake(_left, ARROW_HEIGHT, _width, _height)];
            _popoverArrowView.frame = CGRectMake(_coordinate, 0, ARROW_BASE, ARROW_HEIGHT);
            _popoverArrowView.image = [[UIImage alloc] initWithCGImage: _popoverArrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationDown];
            [_popoverArrowView.image drawInRect:_popoverArrowView.frame];
            
            popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
        case UIPopoverArrowDirectionDown:
            NSLog(@"Down");
            
            _coordinate = ((self.frame.size.width / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(popoverArrowBubbleView.frame.size.width, popoverArrowBubbleView.frame.size.height + ARROW_HEIGHT), NO, 0);
            
            [popoverBubbleView.image drawInRect:CGRectMake(_left, _top, _width, _height)];
            _popoverArrowView.frame = CGRectMake(_coordinate, _height, ARROW_BASE, ARROW_HEIGHT);
            [_popoverArrowView.image drawInRect:_popoverArrowView.frame];
            
            popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
        case UIPopoverArrowDirectionLeft:
            NSLog(@"Left");
            
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(popoverArrowBubbleView.frame.size.width + ARROW_HEIGHT, popoverArrowBubbleView.frame.size.height), NO, 0);
            
            [popoverBubbleView.image drawInRect:CGRectMake(ARROW_HEIGHT, _top, _width, _height)];
            _popoverArrowView.frame = CGRectMake(0, _coordinate, ARROW_HEIGHT, ARROW_BASE);
            _popoverArrowView.image = [[UIImage alloc] initWithCGImage: _popoverArrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationRight];
            [_popoverArrowView.image drawInRect:_popoverArrowView.frame];
            
            popoverArrowBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
        case UIPopoverArrowDirectionRight:
            NSLog(@"Right");
            
            _coordinate = ((self.frame.size.height / 2) + self.arrowOffset) - (ARROW_BASE / 2);
            popoverArrowBubbleView.frame =  CGRectMake(0, 0, _width, _height);
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(popoverArrowBubbleView.frame.size.width + ARROW_HEIGHT, popoverArrowBubbleView.frame.size.height), NO, 0);
            
            [popoverBubbleView.image drawInRect:CGRectMake(_left, _top, _width, _height)];
            _popoverArrowView.frame = CGRectMake(_width, _coordinate, ARROW_HEIGHT, ARROW_BASE);
            _popoverArrowView.image = [[UIImage alloc] initWithCGImage: _popoverArrowView.image.CGImage
                                                          scale: 1.0
                                                    orientation: UIImageOrientationLeft];
            [popoverArrowBubbleView.image drawInRect:_popoverArrowView.frame];
            
            popoverBubbleView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            break;
            
    }
    if (popoverTintColor) {
        popoverArrowBubbleView.image = [popoverArrowBubbleView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        popoverArrowBubbleView.tintColor = popoverTintColor;
    } else {
        popoverArrowBubbleView.image = [popoverArrowBubbleView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        popoverArrowBubbleView.tintColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:.86];
    }
}

@end

