#import <UIKit/UIKit.h>


@interface ScrollFadeImageView : UIView {
    BOOL animating;
    NSInteger currentPosition;

    // animation queue
    UIImageView *outgoingImage;
    UIImageView *centerImage;
    UIImageView *incomingImage;
}

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@property (nonatomic) CGFloat scrollDistance;
@property (nonatomic, strong) NSArray *animationImages;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;

@end
