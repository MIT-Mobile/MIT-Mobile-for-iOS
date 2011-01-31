#import <UIKit/UIKit.h>


@interface ScrollFadeImageView : UIView {
    
    CGFloat scrollDistance;

    NSArray *animationImages;
    NSTimeInterval animationDuration;
    NSTimeInterval animationDelay;
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
@property (nonatomic, retain) NSArray *animationImages;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;

@end
