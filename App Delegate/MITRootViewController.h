#import <UIKit/UIKit.h>

@interface MITRootViewController : UIViewController
@property (nonatomic,copy) NSArray *modules;

- (BOOL)showModuleWithTag:(NSString*)module;
- (BOOL)showModuleWithTag:(NSString*)module animated:(BOOL)animated;
@end
