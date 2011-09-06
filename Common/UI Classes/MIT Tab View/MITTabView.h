#import <UIKit/UIKit.h>

@interface MITTabView : UIView
@property (nonatomic,readonly) NSArray *viewControllers;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithFrame:(CGRect)frame;

- (BOOL)addViewController:(UIViewController*)controller animate:(BOOL)animate;
- (BOOL)insertViewController:(UIViewController*)controller atIndex:(NSUInteger)index animate:(BOOL)animate;

@end
