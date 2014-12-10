#import <UIKit/UIKit.h>

@interface MITLibrariesItemDetailLineCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lineTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *lineDetailLabel;

+ (CGFloat)heightForTitle:(NSString *)title detail:(NSString *)detail tableViewWidth:(CGFloat)width;

@end
