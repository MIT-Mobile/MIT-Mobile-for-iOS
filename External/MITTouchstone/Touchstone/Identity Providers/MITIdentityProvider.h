#import <Foundation/Foundation.h>

@protocol MITIdentityProvider <NSObject>
@property (nonatomic,readonly,strong) NSString *name;
@property (nonatomic,readonly,strong) NSURL *URL;
@property (nonatomic,readonly,strong) NSURLProtectionSpace *protectionSpace;

- (BOOL)canAuthenticateForUser:(NSString*)username;

@optional
/** Translates the passed username into something the Identity Provider can handle.
 *  This is needed mostly because if the MIT IdP; <user> or <user>@mit.edu are valid
 *  usernames if entered by the user, but the IdP will fail if authentication is
 *  attempted using <user>@mit.edu.
 */
- (NSString*)localUserForUser:(NSString*)user;
@end
