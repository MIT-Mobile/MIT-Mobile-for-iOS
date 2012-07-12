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

@interface MITSpringboard : UIViewController <UINavigationControllerDelegate> {
	id<MITSpringboardDelegate> delegate;
    NSArray *primaryModules;
    IconGrid *grid;
    
	NSTimer *checkBannerTimer;
	
    NSMutableDictionary *bannerInfo;
}

@property (nonatomic, assign) id<MITSpringboardDelegate> delegate;
@property (nonatomic, retain) IconGrid *grid;
@property (nonatomic, retain) NSArray *primaryModules;

- (void)pushModuleWithTag:(NSString*)tag;
@end

@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
    NSString *badgeValue;
}

@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) NSString *badgeValue;

@end