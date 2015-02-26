#import <Foundation/Foundation.h>

@protocol MITIdentityProvider;
@protocol MITTouchstoneAuthenticationDelegate;

@interface MITTouchstoneController : NSObject
@property (nonatomic,weak) id<MITTouchstoneAuthenticationDelegate> authenticationDelegate;
@property (nonatomic,readonly,strong) NSURLCredential *storedCredential;
@property (nonatomic,readonly,copy) NSDictionary *userInformation;
@property (nonatomic, readonly, copy) NSString *userEmailAddress;

+ (MITTouchstoneController*)sharedController;
+ (void)setSharedController:(MITTouchstoneController*)sharedController;

+ (NSArray*)allIdentityProviders;
+ (NSURL*)loginEntryPointURL;
+ (id<MITIdentityProvider>)identityProviderForUser:(NSString*)user;

- (void)logout;

- (BOOL)isLoggedIn;
- (void)login:(void (^)(BOOL success, NSError *error))completion;
- (void)loginWithCredential:(NSURLCredential*)credential completion:(void(^)(BOOL success, NSError *error))completion;
@end

@protocol MITTouchstoneAuthenticationDelegate <NSObject>
- (void)touchstoneController:(MITTouchstoneController*)controller presentViewController:(UIViewController*)viewController completion:(void(^)(void))completion;
- (void)touchstoneController:(MITTouchstoneController*)controller dismissViewController:(UIViewController*)viewController completion:(void(^)(void))completion;
@end