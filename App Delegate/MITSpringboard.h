#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "ConnectionWrapper.h"

@class MITSpringboard;

@protocol MITSpringboardDelegate <NSObject>

@optional

- (void)springboard:(MITSpringboard *)springboard didPushModuleForTag:(NSString *)moduleTag;
- (void)springboardDidPopModule:(MITSpringboard *)springboard;

@end

@interface MITSpringboard : UIViewController <JSONLoadedDelegate, UINavigationControllerDelegate, ConnectionWrapperDelegate> {
	
	id<MITSpringboardDelegate> delegate;
	NSInteger navStackDepth;

    NSArray *primaryModules;
    
	NSTimer *checkBannerTimer;
	
    NSMutableDictionary *bannerInfo;
    
    ConnectionWrapper *connection;
    
}

@property (nonatomic, assign) id<MITSpringboardDelegate> delegate;
@property (nonatomic, retain) NSArray *primaryModules;
@property (nonatomic, retain) ConnectionWrapper *connection;

@end

@interface SpringboardIcon : UIButton {
    NSString *moduleTag;
    NSString *badgeValue;
}

@property (nonatomic, retain) NSString *moduleTag;
@property (nonatomic, retain) NSString *badgeValue;

@end