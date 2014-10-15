#import <UIKit/UIKit.h>

@interface MITNewsLoadMoreTableViewCell : UITableViewCell
@property (nonatomic,strong) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@end
