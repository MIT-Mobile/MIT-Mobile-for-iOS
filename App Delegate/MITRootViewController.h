#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MITInterfaceStyle) {
    MITInterfaceStyleSpringboard = 0,
    MITInterfaceStyleDrawer
};

@interface MITRootViewController : UIViewController
@property (nonatomic) MITInterfaceStyle interfaceStyle;
@property (nonatomic,weak) MITModule *activeModule;
@property (nonatomic,copy) NSArray *modules;

- (BOOL)showModuleWithTag:(MITModule*)module;
@end
