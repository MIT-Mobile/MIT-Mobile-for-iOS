#import <UIKit/UIKit.h>

@class MITModule;

@interface MITLauncherViewCell : UICollectionViewCell
@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (nonatomic,weak) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) MITModule *module;

@end
