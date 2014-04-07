#import <Foundation/Foundation.h>

@protocol MITIdentityProvider;
@protocol MITTouchstoneAuthenticationDelegate;

@interface MITTouchstoneController : NSObject
@property (nonatomic,weak) id<MITTouchstoneAuthenticationDelegate> authenticationDelegate;
@property (nonatomic,readonly,copy) NSDictionary *userInformation;

+ (MITTouchstoneController*)sharedController;
+ (void)setSharedController:(MITTouchstoneController*)sharedController;

+ (NSArray*)allIdentityProviders;
+ (NSURL*)loginEntryPointURL;
+ (id<MITIdentityProvider>)identityProviderForCredential:(NSURLCredential*)credential;

- (void)logout;
- (void)login:(void (^)(void))completed;
@end

@protocol MITTouchstoneAuthenticationDelegate <NSObject>
- (void)touchstoneController:(MITTouchstoneController*)controller presentViewController:(UIViewController*)viewController;
- (void)dismissViewControllerForTouchstoneController:(MITTouchstoneController *)controller completion:(void(^)(void))completion;
@end