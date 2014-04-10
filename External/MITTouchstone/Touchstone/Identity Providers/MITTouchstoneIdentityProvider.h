#import <Foundation/Foundation.h>
#import "MITIdentityProvider.h"

@interface MITTouchstoneIdentityProvider : NSObject <MITIdentityProvider>
@property (nonatomic,readonly,strong) NSString *name;
@property (nonatomic,readonly,strong) NSURL *URL;
@property (nonatomic,readonly,strong) NSURLProtectionSpace *protectionSpace;

- (BOOL)canAuthenticateForUser:(NSString*)username;
- (NSString*)localUserForUser:(NSString*)user;
@end
