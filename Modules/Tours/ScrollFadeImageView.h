#import <UIKit/UIKit.h>


@interface ScrollFadeImageView : UIView {
    BOOL _animating;
    NSInteger _currentPosition;

    // animation queue
    UIImageView *_outgoingImage;
    UIImageView *_centerImage;
    UIImageView *_incomingImage;
}

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@property (nonatomic) CGFloat scrollDistance;
@property (nonatomic, copy) NSArray *animationImages;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;

@end
