#import <UIKit/UIKit.h>

@interface MITScrollingNavigationBarCell : UICollectionViewCell
@property (nonatomic,weak) UILabel *titleLabel;

+ (NSDictionary*)textAttributesForSelectedTitle;
+ (NSDictionary*)textAttributesForTitle;

@end
