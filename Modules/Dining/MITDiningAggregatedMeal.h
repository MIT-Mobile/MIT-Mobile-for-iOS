#import <Foundation/Foundation.h>

@class MITDiningMeal, MITDiningHouseVenue;

@interface MITDiningAggregatedMeal : NSObject

@property (nonatomic, strong) NSArray *venues;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *mealName;

@property (nonatomic, readonly) NSString *mealDisplayTitle;

- (instancetype)initWithVenues:(NSArray *)venues date:(NSDate *)date mealName:(NSString *)mealName;
- (MITDiningMeal *)mealForHouseVenue:(MITDiningHouseVenue *)houseVenue;

@end
