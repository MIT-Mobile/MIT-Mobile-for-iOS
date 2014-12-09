#import <UIKit/UIKit.h>

@class MITLibrariesMITHoldItem;

@interface MITLibrariesItemHoldCollectionCell : UICollectionViewCell

- (void)setContent:(MITLibrariesMITHoldItem *)item;
+ (CGFloat)heightForContent:(MITLibrariesMITHoldItem *)item width:(CGFloat)width;

@end
