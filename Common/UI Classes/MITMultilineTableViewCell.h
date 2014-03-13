#import <UIKit/UIKit.h>

@interface MITMultilineTableViewCell : UITableViewCell
@property (nonatomic,readonly,weak) UILabel *headlineLabel;
@property (nonatomic,readonly,weak) UILabel *bodyLabel;

- (id)init;
@end
