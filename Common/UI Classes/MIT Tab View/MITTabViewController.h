#import <UIKit/UIKit.h>

@interface MITTabViewController : UIViewController
@property (nonatomic,readonly) NSArray *viewControllers;

- (id)init;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (BOOL)addViewController:(UIViewController*)controller animate:(BOOL)animate;
- (BOOL)insertViewController:(UIViewController*)controller atIndex:(NSUInteger)index animate:(BOOL)animate;

@end
