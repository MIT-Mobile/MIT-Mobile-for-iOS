#import <Foundation/Foundation.h>

@protocol MITIdentityProvider <NSObject>
@property (nonatomic,readonly,strong) NSString *name;
@property (nonatomic,readonly,strong) NSURL *URL;
@property (nonatomic,readonly,strong) NSURLProtectionSpace *protectionSpace;

- (BOOL)canAuthenticateForUser:(NSString*)username;
@end
