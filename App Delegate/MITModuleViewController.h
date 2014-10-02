#import <UIKit/UIKit.h>

@class MITModuleItem;
@class MITNotification;

@protocol MITModuleViewControllerProtocol <NSObject>
@property(nonatomic,readonly,strong) MITModuleItem *moduleItem;
@property(nonatomic,readonly) BOOL isPushNotificationsEnabled;

- (BOOL)isCurrentUserInterfaceIdiomSupported;
- (BOOL)canReceivePushNotifications;
- (void)didReceivePushNotification:(NSDictionary*)notification;
- (BOOL)handleURL:(NSURL*)url completion:(void(^)(void))completion;
@end

@interface MITModuleViewController : UIViewController <MITModuleViewControllerProtocol>
@property(nonatomic,strong) MITModuleItem *moduleItem;
@property(nonatomic,getter=isPushNotificationsEnabled) BOOL pushNotificationsEnabled;

@property(nonatomic,strong) IBOutlet UIViewController *rootViewController;
@property(nonatomic,copy) NSString *rootViewControllerStoryboardID;
@property(nonatomic) BOOL isRootViewControllerLoaded;

- (void)loadRootViewController;

- (BOOL)isCurrentUserInterfaceIdiomSupported;
- (BOOL)canReceivePushNotifications;
- (void)didReceivePushNotification:(NSDictionary*)notification;
- (BOOL)handleURL:(NSURL*)url completion:(void(^)(void))completion;
@end

@interface MITModuleItem : NSObject
@property(nonatomic,copy) NSString *tag;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *longTitle;

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIImage *selectedImage;

- (instancetype)initWithTag:(NSString*)tag title:(NSString*)title image:(UIImage*)image;
- (instancetype)initWithTag:(NSString*)tag title:(NSString*)title image:(UIImage*)image selectedImage:(UIImage*)selectedImage;
@end
