#import <UIKit/UIKit.h>

@class MITLibrariesWorldcatItem;

@interface MITLibrariesWorldcatItemCollectionCell : UICollectionViewCell

- (void)setContent:(MITLibrariesWorldcatItem *)item;
+ (CGFloat)heightForContent:(MITLibrariesWorldcatItem *)item width:(CGFloat)width;

@end
