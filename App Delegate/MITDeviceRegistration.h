
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

@interface MITDeviceIdentity : NSObject <NSSecureCoding>
@property(nonatomic,copy) NSData *deviceToken;
@property(nonatomic,copy) NSString *deviceIdentifier;
@property(nonatomic,copy) NSString *passcode;

@property(nonatomic,readonly) BOOL isRegistered;
@property(nonatomic,readonly) BOOL isEnabled;

- (instancetype)init;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;

- (void)setDeviceToken:(NSData *)deviceToken completion:(void(^)(NSError *error))block;
- (void)registerDevice:(void(^)(NSError *error))completion;
@end