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
    if (animating || ([self.animationImages count] == 0)) return;
    animating = YES;
    
    incomingImage = [self.animationImages objectAtIndex:currentPosition];
    [self animateSlide];
}

- (void)stopAnimating {
    if (!animating || ([self.animationImages count] == 0)) return;
    animating = NO;
}

- (BOOL)isAnimating {
    return animating;
}

- (void)animateSlide {
    if (!animating) return;
    
    CGRect inFrame = incomingImage.frame;
    inFrame.origin.x = 0;
    incomingImage.frame = inFrame;
    [self addSubview:incomingImage];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:round(self.animationDuration * (1 - CROSSFADE_PROPORTION))];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animateCrossfade)];
    
    inFrame.origin.x = round(-(self.scrollDistance) * (1 - CROSSFADE_PROPORTION));
    incomingImage.frame = inFrame;

    inFrame = centerImage.frame;
    inFrame.origin.x = incomingImage.frame.origin.x - self.scrollDistance;
    centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)animateCrossfade {
    CGRect inFrame = incomingImage.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:round(self.animationDuration * CROSSFADE_PROPORTION)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(cleanupAnimation)];
    
    inFrame.origin.x = -(self.scrollDistance);
    incomingImage.frame = inFrame;
    incomingImage.alpha = 1;
    
    inFrame = centerImage.frame;
    inFrame.origin.x = incomingImage.frame.origin.x - self.scrollDistance;
    centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)cleanupAnimation {
    if (outgoingImage)
        [outgoingImage removeFromSuperview];
    
    currentPosition++;
    if (currentPosition == [self.animationImages count])
        currentPosition = 0;
    
    outgoingImage = centerImage;
    centerImage = incomingImage;
    incomingImage = [self.animationImages objectAtIndex:currentPosition];
    incomingImage.alpha = 0;

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

- (void)dealloc {
    self.animationImages = nil;
}


@end
