#import "ScrollFadeImageView.h"

#define CROSSFADE_PROPORTION 0.30

@interface ScrollFadeImageView (Private)

- (void)animateSlide;
- (void)animateCrossfade;
- (void)cleanupAnimation;

@end



@implementation ScrollFadeImageView

@synthesize animationImages, scrollDistance;

- (NSTimeInterval)animationDuration {
    return animationDuration;
}

- (void)setAnimationDuration:(NSTimeInterval)duration {
    if (duration > 0)
        animationDuration = duration;
}

- (NSTimeInterval)animationDelay {
    return animationDelay;
}

- (void)setAnimationDelay:(NSTimeInterval)delay {
    if (delay > 0)
        animationDelay = delay;
}

- (void)startAnimating {
    if (animating || !animationImages) return;
    animating = YES;
    
    incomingImage = [animationImages objectAtIndex:currentPosition];
    [self animateSlide];
}

- (void)stopAnimating {
    if (!animating || !animationImages) return;
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
    [UIView setAnimationDuration:round(animationDuration * (1 - CROSSFADE_PROPORTION))];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animateCrossfade)];
    
    inFrame.origin.x = round(-scrollDistance * (1 - CROSSFADE_PROPORTION));
    incomingImage.frame = inFrame;

    inFrame = centerImage.frame;
    inFrame.origin.x = incomingImage.frame.origin.x - scrollDistance;
    centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)animateCrossfade {
    CGRect inFrame = incomingImage.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:round(animationDuration * CROSSFADE_PROPORTION)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(cleanupAnimation)];
    
    inFrame.origin.x = -scrollDistance;
    incomingImage.frame = inFrame;
    incomingImage.alpha = 1;
    
    inFrame = centerImage.frame;
    inFrame.origin.x = incomingImage.frame.origin.x - scrollDistance;
    centerImage.frame = inFrame;
    
    [UIView commitAnimations];
}

- (void)cleanupAnimation {
    if (outgoingImage)
        [outgoingImage removeFromSuperview];
    
    currentPosition++;
    if (currentPosition == animationImages.count)
        currentPosition = 0;
    
    outgoingImage = centerImage;
    centerImage = incomingImage;
    incomingImage = [animationImages objectAtIndex:currentPosition];
    incomingImage.alpha = 0;

    [self performSelector:@selector(animateSlide) withObject:nil afterDelay:animationDelay];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        animationDuration = 7.0;
        animationDelay = 0.001;
        scrollDistance = 30.0;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    self.animationImages = nil;
    [super dealloc];
}


@end
