#import <UIKit/UIKit.h>


@interface MITLoadingActivityView : UIView
@property (nonatomic, assign) BOOL usesBackgroundImage;

@property (nonatomic,readonly,weak) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic,readonly,weak) UILabel *textLabel;

@end
