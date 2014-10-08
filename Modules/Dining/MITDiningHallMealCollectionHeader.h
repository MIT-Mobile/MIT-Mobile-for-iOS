#import <UIKit/UIKit.h>

@class MITDiningHallMealCollectionHeader;
@class MITDiningHouseVenue;
@class MITDiningHouseDay;

@protocol MITDiningHallMealCollectionHeaderDelegate <NSObject>

- (void)diningHallHeaderInfoButtonPressedForHouse:(MITDiningHouseVenue *)houseVenue;

@end

@interface MITDiningHallMealCollectionHeader : UICollectionReusableView

@property (nonatomic, weak) id<MITDiningHallMealCollectionHeaderDelegate> delegate;


- (void)setDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName;
+ (CGFloat)heightForDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName collectionViewWidth:(CGFloat)tableWidth;

@end
