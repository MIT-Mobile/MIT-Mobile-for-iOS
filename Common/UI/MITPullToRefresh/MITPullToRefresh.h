#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITPullToRefreshState) {
    MITPullToRefreshStateStopped = 0,
    MITPullToRefreshStateTriggered,
    MITPullToRefreshStateLoading
};

@interface UIScrollView (MITPullToRefresh)

- (void)mit_addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)mit_triggerPullToRefresh;
- (void)mit_stopAnimating;

@property (nonatomic, assign) BOOL mit_showsPullToRefresh;
@property (nonatomic, readonly) MITPullToRefreshState mit_pullToRefreshState;

@end
