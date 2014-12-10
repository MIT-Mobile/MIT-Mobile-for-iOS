#import <UIKit/UIKit.h>

@interface MITToursInfoCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *infoTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

+ (CGSize)sizeForInfoText:(NSString *)infoText buttonText:(NSString *)buttonText;

- (void)configureForInfoText:(NSString *)infoText buttonText:(NSString *)buttonText;

@end
