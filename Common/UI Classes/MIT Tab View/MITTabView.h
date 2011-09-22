#import <UIKit/UIKit.h>

extern NSString* const MITTabViewWillBecomeActiveNotification;
extern NSString* const MITTabViewDidBecomeActiveNotification;
extern NSString* const MITTabViewWillBecomeInactiveNotification;
extern NSString* const MITTabViewDidBecomeInactiveNotification;

@interface MITTabView : UIView
@property (nonatomic,readonly) NSArray *views;
@property (nonatomic,readonly,retain) UIView *contentView;

- (id)init;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (BOOL)addView:(UIView*)view withItem:(UITabBarItem*)item animate:(BOOL)animate;
- (BOOL)insertView:(UIView*)view withItem:(UITabBarItem*)item atIndex:(NSUInteger)index animate:(BOOL)animate;

- (void)tabViewWillBecomeActive:(UIView*)view;
- (void)tabViewDidBecomeActive:(UIView*)view;
- (void)tabViewWillBecomeInactive:(UIView*)view;
- (void)tabViewDidBecomeInactive:(UIView*)view;

@end
