#import "ScrollFadeImageView.h"

#define CROSSFADE_PROPORTION 0.30

@interface ScrollFadeImageView ()

- (void)animateSlide;
- (void)animateCrossfade;
- (void)cleanupAnimation;

@end



@implementation ScrollFadeImageView
- (void)setAnimationImages:(NSArray *)animationImages
{
    NSMutableArray *animationViews = [NSMutableArray array];
    
    for (id<NSObject> image in animationImages)
    {
        UIImageView *imageView = nil;
        
        if ([image isKindOfClass:[UIImageView class]])
        {
            imageView = (UIImageView*)image;
        }
        else if ([image isKindOfClass:[UIImage class]])
        {
            imageView = [[UIImageView alloc] initWithImage:(UIImage*)image];
        }
        else
        {
            DDLogError(@"invalid image class '%@'", NSStringFromClass([image class]));
            break;
        }
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        CGRect frame = imageView.frame;
        frame.size.height = MAX(CGRectGetHeight(frame),CGRectGetHeight(self.bounds));
        frame.size.width= MAX(CGRectGetWidth(frame),CGRectGetWidth(self.bounds));
        imageView.frame = frame;
        [animationViews addObject:imageView];
    }
    
    _animationImages = animationViews;
}

- (void)setAnimationDuration:(NSTimeInterval)duration {
    if (duration > 0)
        _animationDuration = duration;
}

- (void)setAnimationDelay:(NSTimeInterval)delay {
    if (delay > 0)
        _animationDelay = delay;
}

- (void)startAnimating {
    if (_animating || ([self.animationImages count] == 0)) return;
    _animating = YES;
    
    _incomingImage = self.animationImages[_currentPosition];
    [self animateSlide];
}

- (void)stopAnimating {
    if (!_animating || ([self.animationImages count] == 0)) return;
    _animating = NO;
}

- (BOOL)isAnimating {
    return _animating;
}

- (void)animateSlide {
    if (!_animating) return;
    
    CGRect inFrame = _incomingImage.frame;
    inFrame.origin.x = 0;
    _incomingImage.frame = inFrame;
    [self addSubview:_incomingImage];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:round(self.animationDuration * (1 - CROSSFADE_PROPORTION))];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animateCrossfade)];
    
    inFrame.origin.x = round(-(self.scrollDistance) * (1 - CROSSFADE_PROPORTION));
    _incomingImage.frame = inFrame;

    inFrame = _centerImage.frame;
    inFrame.origin.x = _incomingImage.frame.origin.x - self.scrollDistance;
    _centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)animateCrossfade {
    CGRect inFrame = _incomingImage.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:round(self.animationDuration * CROSSFADE_PROPORTION)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(cleanupAnimation)];
    
    inFrame.origin.x = -(self.scrollDistance);
    _incomingImage.frame = inFrame;
    _incomingImage.alpha = 1;
    
    inFrame = _centerImage.frame;
    inFrame.origin.x = _incomingImage.frame.origin.x - self.scrollDistance;
    _centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)cleanupAnimation {
    if (_outgoingImage)
        [_outgoingImage removeFromSuperview];
    
    _currentPosition++;
    if (_currentPosition == [self.animationImages count])
        _currentPosition = 0;
    
    _outgoingImage = _centerImage;
    _centerImage = _incomingImage;
    _incomingImage = self.animationImages[_currentPosition];
    _incomingImage.alpha = 0;

    [self performSelector:@selector(animateSlide) withObject:nil afterDelay:self.animationDelay];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]))
    {
        self.animationDuration = 7.0;
        self.animationDelay = 0.001;
        self.scrollDistance = 30.0;
    }
    return self;
}


@end
