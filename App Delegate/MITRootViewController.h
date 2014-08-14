#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITInterfaceStyle) {
    MITInterfaceStyleSpringboard = 0,
    MITInterfaceStyleDrawer
};

@interface MITRootViewController : UIViewController
@property (nonatomic) MITInterfaceStyle interfaceStyle;
@property (nonatomic,copy) NSArray *modules;
@property (nonatomic,getter=isLeftDrawerVisible) BOOL leftDrawerVisible;

- (BOOL)showModuleWithTag:(NSString*)module;
- (BOOL)showModuleWithTag:(NSString*)module animated:(BOOL)animated;

#pragma mark Drawer-style interface specific
// Has no effect when using the springboard interface style
- (void)setLeftDrawerVisible:(BOOL)visible animated:(BOOL)animated;
@end
