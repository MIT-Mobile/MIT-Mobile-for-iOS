#import <UIKit/UIKit.h>

@class MITLibrariesMITItem;

@interface MITLibrariesItemLoanFineCollectionCell : UICollectionViewCell

- (void)setContent:(MITLibrariesMITItem *)item;
+ (CGFloat)heightForContent:(MITLibrariesMITItem *)item width:(CGFloat)width;

@end
