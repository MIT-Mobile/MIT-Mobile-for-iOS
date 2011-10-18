#import <UIKit/UIKit.h>

@class MITSegmentControl;

@interface MITTabBar : UIControl
@property (nonatomic,copy) NSArray *items;

@property (nonatomic,retain) UIColor *tintColor;
@property (nonatomic,retain) UIColor *selectedTintColor;

@property (nonatomic,retain) UIImage *tabImage;
@property (nonatomic,retain) UIImage *selectedTabImage;

@property (nonatomic) NSInteger selectedSegmentIndex;

- (void)insertSegmentWithItem:(UITabBarItem*)item atIndex:(NSInteger)index animated:(BOOL)animated;
- (void)removeSegmentWithItem:(UITabBarItem*)item animated:(BOOL)animated;
- (void)removeSegmentAtIndex:(NSInteger)index animated:(BOOL)animated;
@end
