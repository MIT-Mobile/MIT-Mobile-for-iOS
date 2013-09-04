#import <UIKit/UIKit.h>

@class IconGrid;
@class MITModule;

@interface MITSpringboard : UIViewController <UINavigationControllerDelegate>
@property (nonatomic,strong) IconGrid *grid;
@property (nonatomic,strong) NSArray *primaryModules;

- (void)pushModuleWithTag:(NSString*)tag;
@end

@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
    NSString *badgeValue;
}

@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) NSString *badgeValue;

@end