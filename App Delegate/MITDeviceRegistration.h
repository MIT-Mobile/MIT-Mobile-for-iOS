
#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"

@interface MITIdentity : NSObject
{
	NSString *deviceID;
	NSString *passKey;
}

- (id) initWithDeviceId: (NSString *)aDeviceId passKey: (NSString *)aPassKey;

- (NSMutableDictionary *) mutableDictionary;

@property (readonly) NSString *deviceID;
@property (readonly) NSString *passKey;
@end


@interface MITDeviceRegistration : NSObject {

}

+ (void) registerNewDeviceWithToken: (NSData *)deviceToken;
+ (void) newDeviceToken: (NSData *)deviceToken;
+ (MITIdentity *) identity;
@end

@interface MITIdentityLoadedDelegate : NSObject <JSONLoadedDelegate> {
	NSData *deviceToken;
}

@property (nonatomic, retain) NSData *deviceToken;

+ (MITIdentityLoadedDelegate *) withDeviceToken: (NSData *)deviceToken;
@end
