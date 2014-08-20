#import <UIKit/UIKit.h>

@class MITDiningHouseVenue;
@class MITDiningHouseDay;

@interface MITDiningHallMealCollectionHeader : UICollectionReusableView

- (void)setDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName;
+ (CGFloat)heightForDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName collectionViewWidth:(CGFloat)tableWidth;

@end
