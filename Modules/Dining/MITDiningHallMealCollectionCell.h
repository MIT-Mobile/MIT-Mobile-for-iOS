#import <UIKit/UIKit.h>

@class MITDiningHallMealCollectionCell;
@class MITDiningMenuItem;

@interface MITDiningHallMealCollectionCell : UICollectionViewCell

@property (nonatomic, strong) MITDiningMenuItem *menuItem;

+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem width:(CGFloat)width;

@end
