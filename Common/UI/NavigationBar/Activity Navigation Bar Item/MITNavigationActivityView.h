#import <Foundation/Foundation.h>


@interface MITNavigationActivityView : UIView
@property (nonatomic, readonly, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, readonly, retain) NSString *title;

- (void)startActivityWithTitle:(NSString *)title;
- (void)stopActivity;

@end
