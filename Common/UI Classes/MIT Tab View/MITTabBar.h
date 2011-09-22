#import <UIKit/UIKit.h>

@class MITSegmentControl;

@interface MITTabBar : UIControl
@property (nonatomic,copy) NSArray *items;
@property (nonatomic,retain) UIColor *tintColor;
@property (nonatomic,retain) UIColor *selectedTintColor;
@property (nonatomic) NSInteger selectedSegmentIndex;

- (void)insertSegmentWithItem:(UITabBarItem*)item atIndex:(NSUInteger)index animated:(BOOL)animated;
@end
