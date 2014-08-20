#import <UIKit/UIKit.h>

@class MITDiningMenuItem;

@interface MITDiningHallMealCollectionCell : UICollectionViewCell

- (void)setMenuItem:(MITDiningMenuItem *)menuItem;
+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem width:(CGFloat)width;

@end
