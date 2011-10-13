#import <UIKit/UIKit.h>

@interface MITTabViewItem : UITabBarItem
@property (nonatomic,retain) UIView *header;

+ (id)tabBarItemWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag;
+ (id)tabBarItemWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag header:(UIView*)header;
- (id)initWithTitle:(NSString*)title image:(UIImage*)image tag:(NSUInteger)tag header:(UIView*)header;
@end
