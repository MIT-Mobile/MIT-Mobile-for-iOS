#import "ECSlidingViewController.h"

@class MITNotification;
@class MITModuleViewController;

@interface MITSlidingViewController : UIViewController
@property(nonatomic,weak) IBOutlet ECSlidingViewController *slidingViewController;
@property(nonatomic,copy) NSString *slidingViewControllerStoryboardId;

@property(nonatomic,copy) NSArray *viewControllers;
@property(nonatomic,weak) UIViewController *visibleViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;

- (IBAction)toggleViewControllerPicker:(id)sender;
- (void)setVisibleViewControllerWithModuleName:(NSString*)name;
@end
