
#import <Foundation/Foundation.h>

@interface MITIdentity : NSObject
@property (readonly) NSString *deviceID;
@property (readonly) NSString *passKey;

- (id)initWithDeviceId:(NSString *)aDeviceId passKey:(NSString *)aPassKey;
- (NSMutableDictionary *) mutableDictionary;
@end


@interface MITDeviceRegistration : NSObject
+ (void)registerNewDeviceWithToken:(NSData*)deviceToken;
+ (void)registerDeviceWithToken:(NSData*)deviceToken registered:(void (^)(MITIdentity *identity,NSError *error))block;
+ (void)newDeviceToken:(NSData*)deviceToken;
+ (MITIdentity *)identity;
+ (void)clearIdentity;
@end

