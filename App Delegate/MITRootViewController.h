#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITInterfaceStyle) {
    MITInterfaceStyleSpringboard = 0,
    MITInterfaceStyleDrawer
};

@interface MITRootViewController : UIViewController
@property (nonatomic) MITInterfaceStyle interfaceStyle;

@end
