#import <UIKit/UIKit.h>

@class MITModule;

@interface MITLauncherListViewCell : UITableViewCell
@property (nonatomic,assign) BOOL shouldUseShortModuleNames;

@property (nonatomic,weak) IBOutlet UIImageView *moduleImageView;
@property (nonatomic,weak) IBOutlet UILabel *moduleNameLabel;
@property (nonatomic,strong) MITModule *module;

@end
