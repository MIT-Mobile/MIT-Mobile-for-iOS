#import <UIKit/UIKit.h>

@class MITSpringboard;
@class IconGrid;
@class MITModule;

@protocol MITSpringboardDelegate <NSObject>

@optional

- (void)springboard:(MITSpringboard *)springboard didPushModuleForTag:(NSString *)moduleTag;
- (void)springboard:(MITSpringboard *)springboard willPushModule:(MITModule*)module;
- (void)springboard:(MITSpringboard *)springboard didPushModule:(MITModule*)module;

- (void)springboard:(MITSpringboard *)springboard willPopModule:(MITModule*)module;
- (void)springboard:(MITSpringboard *)springboard didPopModule:(MITModule*)module;

@end

@interface MITSpringboard : UIViewController <UINavigationControllerDelegate>
@property (nonatomic,weak) id<MITSpringboardDelegate> delegate;
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