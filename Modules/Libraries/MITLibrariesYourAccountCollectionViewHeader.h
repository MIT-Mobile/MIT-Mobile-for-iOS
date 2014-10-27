#import <UIKit/UIKit.h>

@interface MITLibrariesYourAccountCollectionViewHeader : UICollectionReusableView

- (void)setAttributedString:(NSAttributedString *)attributedString;
+ (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width;

@end
