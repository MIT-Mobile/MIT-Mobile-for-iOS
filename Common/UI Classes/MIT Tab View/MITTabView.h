#import <UIKit/UIKit.h>

extern NSString * const MITTabViewWillBecomeActiveNotification;
extern NSString * const MITTabViewDidBecomeActiveNotification;
extern NSString * const MITTabViewWillBecomeInactiveNotification;
extern NSString * const MITTabViewDidBecomeInactiveNotification;

@class MITTabView;

@protocol MITTabViewDelegate <NSObject>
@optional
- (void)tabView:(MITTabView*)tabView viewWillBecomeActive:(UIView*)view;
- (void)tabView:(MITTabView*)tabView viewDidBecomeActive:(UIView*)view;
- (void)tabView:(MITTabView*)tabView viewWillBecomeInactive:(UIView*)view;
- (void)tabView:(MITTabView*)tabView viewDidBecomeInactive:(UIView*)view;

- (CGFloat)tabView:(MITTabView*)tabView heightOfHeaderForView:(UIView*)view;
- (UIView*)tabView:(MITTabView*)tabView headerForView:(UIView*)view;
@end

@interface MITTabView : UIView
@property (nonatomic,assign) id<MITTabViewDelegate> delegate;
@property (nonatomic,readonly) NSArray *views;
@property (nonatomic,readonly,retain) UIView *contentView;
@property (nonatomic,readonly,assign) UIView *activeView;
@property (nonatomic) BOOL tabBarHidden;

- (BOOL)addView:(UIView*)view withItem:(UITabBarItem*)item animate:(BOOL)animate;
- (BOOL)insertView:(UIView*)view withItem:(UITabBarItem*)item atIndex:(NSInteger)index animate:(BOOL)animate;

- (void)selectTabAtIndex:(NSInteger)index;

@end
