#import <UIKit/UIKit.h>

@interface MITNewsLoadMoreCollectionViewCell : UICollectionViewCell
@property (nonatomic,strong) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@end
