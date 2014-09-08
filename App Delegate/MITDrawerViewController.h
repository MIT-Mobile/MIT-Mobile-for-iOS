#import <UIKit/UIKit.h>

@class MITGradientView;

@interface MITDrawerViewController : UIViewController
@property (nonatomic,copy) NSArray *modules;
@property (nonatomic,weak) MITModule *selectedModule;

@end
