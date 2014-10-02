#import "ECSlidingViewController.h"
#import "MITModuleViewController.h"

@class MITNotification;
@class MITModuleViewController;

@interface MITSlidingViewController : UIViewController
@property(nonatomic,weak) IBOutlet ECSlidingViewController *slidingViewController;
@property(nonatomic,copy) NSString *slidingViewControllerStoryboardId;

@property(nonatomic,copy) NSArray *viewControllers;
@property(nonatomic,weak) UIViewController<MITModuleViewControllerProtocol> *visibleViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;

- (IBAction)toggleViewControllerPicker:(id)sender;
- (void)setVisibleModuleWithTag:(NSString *)moduleTag;
- (BOOL)setVisibleModuleWithNotification:(NSDictionary*)notification;
@end
