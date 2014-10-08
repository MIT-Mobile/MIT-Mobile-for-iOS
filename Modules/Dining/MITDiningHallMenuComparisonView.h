#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class MITDiningHallMenuComparisonView, MITDiningAggregatedMeal;

@protocol MITDiningCompareViewDelegate <NSObject>

@required
- (NSString *)titleForCompareView:(MITDiningHallMenuComparisonView *)compareView;
- (NSInteger)numberOfSectionsInCompareView:(MITDiningHallMenuComparisonView *)compareView;
- (NSString *)compareView:(MITDiningHallMenuComparisonView *)compareView titleForSection:(NSInteger)section;
- (NSString *)compareView:(MITDiningHallMenuComparisonView *)compareView subtitleForSection:(NSInteger)section;
- (NSInteger)compareView:(MITDiningHallMenuComparisonView *)compareView numberOfItemsInSection:(NSInteger) section;
- (UICollectionViewCell *)compareView:(MITDiningHallMenuComparisonView *)compareView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)compareView:(MITDiningHallMenuComparisonView *)compareView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (void) compareViewDidEndDecelerating:(MITDiningHallMenuComparisonView *)compareView;

@end

@interface MITDiningHallMenuComparisonView : UIView

@property (nonatomic, readonly, strong) UILabel *headerView;
@property (nonatomic, strong) MITDiningAggregatedMeal *aggregateMeal;
@property (nonatomic, assign) CGFloat columnWidth;

@property (nonatomic, weak) id<MITDiningCompareViewDelegate> delegate;
@property (nonatomic, assign) BOOL isScrolling;

- (void)reloadData;
- (void)resetScrollOffset;
- (void)setScrollOffsetAgainstRightEdge;
- (void)setScrollOffset:(CGPoint) offset animated:(BOOL)animated;
- (CGPoint)contentOffset;

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

@end