#import "ECSlidingViewController.h"

@class MITModule;
@class MITNotification;

@interface MITSlidingViewController : UIViewController
@property(nonatomic,weak) ECSlidingViewController *slidingViewController;
@property(nonatomic,copy) NSArray *modules;
@property(nonatomic,weak) MITModule *visibleModule;

- (instancetype)initWithModules:(NSArray*)modules;

- (void)setVisibleModuleWithTag:(NSString*)moduleTag;
- (BOOL)setVisibleModuleWithNotification:(MITNotification*)notification;
- (BOOL)setVisibleModuleWithURL:(NSURL*)url;

- (IBAction)toggleAnchorRight:(id)sender;
@end
