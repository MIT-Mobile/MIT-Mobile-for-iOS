#import <UIKit/UIKit.h>
#import "DiningHallMenuComparisonCell.h"
#import "DiningHallMenuComparisonNoMealsCell.h"
#import "MealReference.h"

@class DiningHallMenuCompareView;

@protocol DiningCompareViewDelegate <NSObject>

@required
- (NSString *) titleForCompareView:(DiningHallMenuCompareView *)compareView;
- (NSInteger) numberOfSectionsInCompareView:(DiningHallMenuCompareView *)compareView;

- (NSString *) compareView:(DiningHallMenuCompareView *)compareView titleForSection:(NSInteger)section;
- (NSString *) compareView:(DiningHallMenuCompareView *)compareView subtitleForSection:(NSInteger)section;
- (NSInteger) compareView:(DiningHallMenuCompareView *)compareView numberOfItemsInSection:(NSInteger) section;
- (PSTCollectionViewCell *) compareView:(DiningHallMenuCompareView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat) compareView:(DiningHallMenuCompareView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface DiningHallMenuCompareView : UIView

@property (nonatomic, readonly, strong) UILabel * headerView;
@property (nonatomic, strong) MealReference *mealRef;
@property (nonatomic, assign) CGFloat columnWidth;

@property (nonatomic, assign) id<DiningCompareViewDelegate> delegate;

- (void) reloadData;
- (void) resetScrollOffset;

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

+ (NSString *) stringForMeal:(NSString *)mealName onDate:(NSDate *)date;

@end
