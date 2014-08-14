#import <UIKit/UIKit.h>

@interface MITRootViewController : UIViewController
@property (nonatomic,copy) NSArray *modules;
@property (nonatomic,getter=isLeftDrawerVisible) BOOL leftDrawerVisible;

- (BOOL)showModuleWithTag:(NSString*)module;
- (BOOL)showModuleWithTag:(NSString*)module animated:(BOOL)animated;
- (void)setLeftDrawerVisible:(BOOL)visible animated:(BOOL)animated;
@end
