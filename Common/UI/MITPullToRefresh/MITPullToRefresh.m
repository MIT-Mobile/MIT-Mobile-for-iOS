#import "MITPullToRefresh.h"
#import <objc/runtime.h>

static CGFloat const MITPullToRefreshViewHeight = 70;
static CGFloat const MITPullToRefreshTriggerHeight = 70;

static void * MITPullToRefreshScrollViewProperty_pullToRefreshView = &MITPullToRefreshScrollViewProperty_pullToRefreshView;

#pragma mark MITPullToRefreshView "public" interface

@interface MITPullToRefreshView : UIView

@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) MITPullToRefreshState state;
@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

- (void)activateWithScrollView:(UIScrollView *)scrollView;
- (void)deactivate;

- (void)startLoading;
- (void)stopAnimating;

@end

#pragma mark UIScrollView (MITPullToRefresh_Internal)

@interface UIScrollView (MITPullToRefresh_Internal)

@property (nonatomic, strong) MITPullToRefreshView *pullToRefreshView;

@end

#pragma mark UIScrollView (MITPullToRefresh)

@implementation UIScrollView (MITPullToRefresh)

- (void)mit_addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
{
    if (!self.pullToRefreshView) {
        MITPullToRefreshView *view = [[MITPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, MITPullToRefreshViewHeight)];
        self.pullToRefreshView = view;
        [self addSubview:view];
    }
    
    self.pullToRefreshView.pullToRefreshActionHandler = actionHandler;
    self.mit_showsPullToRefresh = YES;
}

- (void)mit_triggerPullToRefresh
{
    [self.pullToRefreshView startLoading];
}

- (void)mit_stopAnimating
{
    [self.pullToRefreshView stopAnimating];
}

- (void)setPullToRefreshView:(MITPullToRefreshView *)pullToRefreshView
{
    [self willChangeValueForKey:@"pullToRefreshView"];
    objc_setAssociatedObject(self, MITPullToRefreshScrollViewProperty_pullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"pullToRefreshView"];
}

- (MITPullToRefreshView *)pullToRefreshView
{
    return objc_getAssociatedObject(self, MITPullToRefreshScrollViewProperty_pullToRefreshView);
}

- (void)setMit_showsPullToRefresh:(BOOL)mit_showsPullToRefresh
{
    self.pullToRefreshView.hidden = !mit_showsPullToRefresh;
    
    if (mit_showsPullToRefresh) {
        [self.pullToRefreshView activateWithScrollView:self];
    } else {
        [self.pullToRefreshView deactivate];
    }
}

- (BOOL)mit_showsPullToRefresh
{
    return self.pullToRefreshView.isActive;
}

- (MITPullToRefreshState)mit_pullToRefreshState
{
    return self.pullToRefreshView.state;
}

@end

#pragma mark MITPullToRefreshView "private" interface

static NSString * const StartingProgressViewAnimationGroupKey = @"StartingProgressViewAnimationGroupKey";
static NSString * const StartingLoadingViewAnimationGroupKey = @"StartingLoadingViewAnimationGroupKey";

static NSString * const LoadingViewChoppyRotationKey = @"LoadingViewChoppyRotationKey";

static NSString * const EndingLoadingViewAnimationGroupKey = @"EndingLoadingViewAnimationGroupKey";

@interface MITPullToRefreshView ()

@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) MITPullToRefreshState state;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) UIEdgeInsets unmodifiedInsets;
@property (nonatomic, assign) BOOL originalAlwaysBounceVertical;

@property (nonatomic, strong) UIImageView *progressView;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) UIImageView *loadingView;

@end

#pragma mark MITPullToRefreshView

@implementation MITPullToRefreshView : UIView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = MITPullToRefreshStateStopped;
        
        self.progressView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mit_ptrf_progress_wheel"]];
        self.progressView.frame = CGRectMake(0, 0, 25, 25);
        self.progressView.alpha = 0;
        [self addSubview:self.progressView];
        
        self.loadingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mit_ptrf_loading_wheel"]];
        self.loadingView.frame = self.progressView.frame;
        self.loadingView.alpha = 0;
        [self addSubview:self.loadingView];
        
        self.maskLayer = [CAShapeLayer layer];
        self.maskLayer.frame = self.progressView.frame;
    }
    
    return self;
}

- (void)layoutSubviews
{
    CGRect progressViewBounds = [self.progressView bounds];
    CGPoint origin = CGPointMake(roundf((CGRectGetWidth(self.bounds) - CGRectGetWidth(progressViewBounds)) / 2), roundf(( CGRectGetHeight(self.bounds) - CGRectGetHeight(progressViewBounds)) / 2));
    CGRect progressViewFrame = CGRectMake(origin.x, origin.y - 10, CGRectGetWidth(progressViewBounds), CGRectGetHeight(progressViewBounds));
    
    self.progressView.frame = progressViewFrame;
    self.maskLayer.frame = self.progressView.bounds;
    self.loadingView.frame = self.progressView.frame;
}

- (void)activateWithScrollView:(UIScrollView *)scrollView
{
    if (self.isActive) {
        return;
    }
    
    self.isActive = YES;
    self.scrollView = scrollView;
    self.unmodifiedInsets = scrollView.contentInset;
    
    self.originalAlwaysBounceVertical = scrollView.alwaysBounceVertical;
    scrollView.alwaysBounceVertical = YES;
    
    [self observeScrollView:scrollView];
}

- (void)deactivate
{
    if (!self.isActive) {
        return;
    }
    
    self.isActive = NO;
    [self unobserveScrollView:self.scrollView];
    self.scrollView.alwaysBounceVertical = self.originalAlwaysBounceVertical;
    self.scrollView = nil;
}

- (void)startLoading
{
    self.state = MITPullToRefreshStateLoading;
    [self setScrollViewContentInsetForLoadingAnimated:YES];
    [self startAnimating];
    self.pullToRefreshActionHandler();
}

- (void)startAnimating
{
    // Rotate and fade out progress view
    CABasicAnimation *progressSmoothRotationAnimation = [CABasicAnimation animation];
    progressSmoothRotationAnimation.keyPath = @"transform.rotation.z";
    progressSmoothRotationAnimation.duration = 1.2;
    progressSmoothRotationAnimation.fromValue = @0;
    progressSmoothRotationAnimation.toValue = @(M_PI);
    
    CABasicAnimation *progressFadeOutAnimation = [CABasicAnimation animation];
    progressFadeOutAnimation.keyPath = @"alpha";
    progressFadeOutAnimation.duration = 1.0;
    progressFadeOutAnimation.fromValue = @1;
    progressFadeOutAnimation.toValue = @0;
    
    CAAnimationGroup *startingProgressViewRotationGroup = [[CAAnimationGroup alloc] init];
    startingProgressViewRotationGroup.animations = @[progressSmoothRotationAnimation, progressFadeOutAnimation];
    startingProgressViewRotationGroup.duration = 1.2;
    
    // Rotate and fade in loading view
    CABasicAnimation *loadingSmoothRotationAnimation = [CABasicAnimation animation];
    loadingSmoothRotationAnimation.keyPath = @"transform.rotation.z";
    loadingSmoothRotationAnimation.duration = 1.2;
    loadingSmoothRotationAnimation.fromValue = @0;
    loadingSmoothRotationAnimation.toValue = @(M_PI);
    
    CABasicAnimation *loadingFadeOutAnimation = [CABasicAnimation animation];
    loadingFadeOutAnimation.keyPath = @"alpha";
    loadingFadeOutAnimation.duration = 1.0;
    loadingFadeOutAnimation.fromValue = @0;
    loadingFadeOutAnimation.toValue = @1;
    
    CAAnimationGroup *startingLoadingViewRotationGroup = [[CAAnimationGroup alloc] init];
    startingLoadingViewRotationGroup.animations = @[loadingSmoothRotationAnimation, loadingFadeOutAnimation];
    startingLoadingViewRotationGroup.duration = 1.2;
    
    // Use this to begin the choppy rotation animation after the starting animations finish
    startingLoadingViewRotationGroup.delegate = self;
    
    [self.progressView.layer addAnimation:startingProgressViewRotationGroup forKey:nil];
    [self.loadingView.layer addAnimation:startingLoadingViewRotationGroup forKey:nil];
    self.progressView.alpha = 0;
    self.loadingView.alpha = 1;
    self.loadingView.transform = CGAffineTransformMakeRotation(M_PI);
}

- (void)stopAnimating
{
    self.state = MITPullToRefreshStateStopped;
    [self resetScrollViewContentInsetAnimated:YES];
    self.loadingView.alpha = 0;
    [self.loadingView.layer removeAnimationForKey:LoadingViewChoppyRotationKey];
    [self updateViewForProgress:0];
}

#pragma mark CAAnimation Delegate

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished
{
    // Begin choppy loading rotation animation
    CAKeyframeAnimation *loadingChoppyRotationAnimation = [CAKeyframeAnimation animation];
    loadingChoppyRotationAnimation.keyPath = @"transform.rotation.z";
    loadingChoppyRotationAnimation.duration = 0.9;
    double pi_6 = M_PI / 6.0;
    loadingChoppyRotationAnimation.values = @[@(pi_6), @(2.0 * pi_6), @(3.0 * pi_6), @(4.0 * pi_6), @(5.0 * pi_6), @(M_PI), @(7.0 * pi_6), @(8.0 * pi_6), @(9.0 * pi_6), @(10.0 * pi_6), @(11.0 * pi_6), @(2.0 * M_PI)];
    loadingChoppyRotationAnimation.calculationMode = kCAAnimationDiscrete;
    loadingChoppyRotationAnimation.repeatCount = HUGE_VALF;
    loadingChoppyRotationAnimation.additive = YES;
    
    [self.loadingView.layer addAnimation:loadingChoppyRotationAnimation forKey:LoadingViewChoppyRotationKey];
}

#pragma mark KVO

- (void)observeScrollView:(UIScrollView *)scrollView
{
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)unobserveScrollView:(UIScrollView *)scrollView
{
    [scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [scrollView removeObserver:self forKeyPath:@"frame"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    } else if ([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    [self adjustFrameOffset];
    CGFloat pullingDownHeight = -1 * (contentOffset.y + self.unmodifiedInsets.top);
    
    switch (self.state) {
        case MITPullToRefreshStateStopped: {
            if (self.scrollView.isDragging && pullingDownHeight >= MITPullToRefreshTriggerHeight) {
                self.state = MITPullToRefreshStateTriggered;
            }
            break;
        }
        case MITPullToRefreshStateTriggered: {
            if (!self.scrollView.isDragging) {
                [self startLoading];
            }
            break;
        }
        case MITPullToRefreshStateLoading: {
            [self setScrollViewContentInsetForLoadingAnimated:NO];
            break;
        }
    }
    
    if (self.state == MITPullToRefreshStateLoading) {
        [self setScrollViewContentInsetForLoadingAnimated:NO];
    } else {
        CGFloat pullingDownHeight = -1 * (contentOffset.y + self.unmodifiedInsets.top);
        
        if (!self.scrollView.isDragging && self.state == MITPullToRefreshStateTriggered) {
            [self startLoading];
        } else if (pullingDownHeight >= MITPullToRefreshTriggerHeight && self.scrollView.isDragging && self.state == MITPullToRefreshStateStopped) {
            self.state = MITPullToRefreshStateTriggered;
        } else if (pullingDownHeight < MITPullToRefreshTriggerHeight && self.state != MITPullToRefreshStateStopped) {
            self.state = MITPullToRefreshStateStopped;
        }
        
        if (pullingDownHeight > 0 && self.state != MITPullToRefreshStateLoading) {
            [self updateViewForProgress:(pullingDownHeight * 1 / MITPullToRefreshTriggerHeight)];
        }
    }
}

- (void)updateViewForProgress:(CGFloat)progress
{
    progress = MAX(0, MIN(1.0, progress));
    CGFloat alphaThreshold = 0.25;
    
    self.progressView.alpha = MIN(1, (progress / alphaThreshold));
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    // We want to always show the top line, and then unmask the lines fully, one at a time
    // This code breaks non-alpha-changing section of the progress into 11ths (since there are 12 lines and the first line is always shown, even at 0%)
    // and determines a number of lines to show by starting with 1 and going up to 12 chunks of pi/6 rad
    CGFloat numberOfLines = (11 * MAX(0, (progress - alphaThreshold))) / (1 - alphaThreshold);
    numberOfLines = floorf(numberOfLines) + 1;
    CGFloat progressRadians = numberOfLines * (M_PI / 6);
    
    // Start position is straight upward, minus half the section of a line
    // We are going to use clockwise calculation since that is the direction we want the mask to unfold in
    CGFloat startRadians = -M_PI_2 - (M_PI / 12);
    
    CGPoint maskCenter = CGPointMake(CGRectGetWidth(self.maskLayer.frame) / 2.0, CGRectGetWidth(self.maskLayer.frame) / 2.0);
    CGFloat radius = CGRectGetWidth(self.maskLayer.frame) / 2.0;
    
    UIBezierPath *progressMaskPath = [UIBezierPath bezierPath];
    [progressMaskPath addArcWithCenter:maskCenter radius:radius startAngle:startRadians endAngle:(startRadians + progressRadians) clockwise:YES];
    [progressMaskPath addLineToPoint:maskCenter];
    [progressMaskPath closePath];
    
    self.maskLayer.path = progressMaskPath.CGPath;
    
    self.progressView.layer.mask = self.maskLayer;
    
    [CATransaction commit];
}

- (void)resetScrollViewContentInsetAnimated:(BOOL)animated
{
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.unmodifiedInsets.top;
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.scrollView.contentInset = currentInsets;
        } completion:nil];
    } else {
        self.scrollView.contentInset = currentInsets;
    }
}

- (void)setScrollViewContentInsetForLoadingAnimated:(BOOL)animated
{
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, self.unmodifiedInsets.top + self.bounds.size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.scrollView.contentInset = currentInsets;
        } completion:nil];
    } else {
        self.scrollView.contentInset = currentInsets;
    }
}

- (void)adjustFrameOffset
{
    CGRect frame = self.frame;
    frame.origin.y = self.scrollView.contentOffset.y;
    self.frame = frame;
}

@end
