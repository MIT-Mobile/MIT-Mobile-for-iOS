#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

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
- (UICollectionViewCell *) compareView:(DiningHallMenuCompareView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat) compareView:(DiningHallMenuCompareView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (void) compareViewDidEndDecelerating:(DiningHallMenuCompareView *)compareView;
@end

@interface DiningHallMenuCompareView : UIView

@property (nonatomic, readonly, strong) UILabel * headerView;
@property (nonatomic, strong) MealReference *mealRef;
@property (nonatomic, assign) CGFloat columnWidth;

@property (nonatomic, weak) id<DiningCompareViewDelegate> delegate;
@property (nonatomic, assign) BOOL isScrolling;

- (void) reloadData;
- (void) resetScrollOffset;
- (void) setScrollOffsetAgainstRightEdge;
- (void) setScrollOffset:(CGPoint) offset animated:(BOOL)animated;
- (CGPoint) contentOffset;

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

+ (NSString *) stringForMeal:(NSString *)mealName onDate:(NSDate *)date;

@end
