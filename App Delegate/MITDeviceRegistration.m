#import "MITDeviceRegistration.h"
//#import "MITTouchstoneRequestOperation+MITMobileV2.h"

static NSString * const MITDeviceTypeKey = @"device_type";
static NSString * const MITDeviceTypeApple = @"apple";

static NSString* MITHexStringFromNSData(NSData* data) {
    if (!data) {
        return nil;
    }

    NSMutableString *hexString = [[NSMutableString alloc] init];
    NSUInteger numberOfBytes = data.length;
    const char *bytes = (const char*)data.bytes;

    for (NSUInteger index = 0; index < numberOfBytes; ++index) {
        [hexString appendFormat:@"%02hhx",bytes[index]];
    }

    return hexString;
}

@implementation MITIdentity
- (id)initWithDeviceId:(NSString *)aDeviceId passKey:(NSString *)aPassKey {
	self = [super init];
	if (self) {
		_deviceID = aDeviceId;
		_passKey = aPassKey;
	}
	return self;
}

- (NSMutableDictionary *)mutableDictionary {
	return [@{MITDeviceIdKey : self.deviceID,
              MITPassCodeKey : self.passKey,
              MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];
}

@end

@implementation MITDeviceRegistration
+ (NSString *)stringFromToken:(NSData *)deviceToken {
	NSString *hex = [deviceToken description]; // of the form "<21d34 2323a 12324>"
	// eliminate the "<" and ">" and " "
	hex = [hex stringByReplacingOccurrencesOfString:@"<" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@">" withString:@""];
	hex = [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
	return hex;
}

+ (void)registerNewDeviceWithToken:(NSData *)deviceToken
{
    [self registerNewDeviceWithToken:deviceToken completion:nil];
}

+ (void)registerNewDeviceWithToken:(NSData *)deviceToken completion:(void(^)(BOOL success))block
{
	NSMutableDictionary *parameters = [@{MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];
	if(deviceToken) {		
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}		

//    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"register" parameters:parameters];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {
//        if ([registerObject isKindOfClass:[NSDictionary class]]) {
//            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];
//        }
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            if (block) {
//                block(YES);
//            }
//        }];
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        DDLogError(@"device registration failed: %@", [error localizedDescription]);
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            if (block) {
//                block(NO);
//            }
//        }];
//    }];
//
//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (void)registerDeviceWithToken:(NSData*)deviceToken registered:(void (^)(MITIdentity *identity,NSError *error))block
{
//	NSMutableDictionary *parameters = [@{MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];
//
//	if(deviceToken) {
//		parameters[@"device_token"] = [self stringFromToken:deviceToken];
//		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
//	}
//
//    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"register" parameters:parameters];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {
//
//        if ([registerObject isKindOfClass:[NSDictionary class]]) {
//            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];
//
//            if (block) {
//                block([MITDeviceRegistration identity],nil);
//            }
//        } else {
//            if (block) {
//                NSError *error = [NSError errorWithDomain:NSURLErrorDomain
//                                                     code:NSURLErrorBadServerResponse
//                                                 userInfo:@{NSLocalizedDescriptionKey : @"unable to register device, invalid response from server"}];
//                block([MITDeviceRegistration identity], error);
//            }
//        }
//
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        if (block) {
//            block([MITDeviceRegistration identity], error);
//        }
//    }];

//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (void)newDeviceToken:(NSData *)deviceToken
{
    [self newDeviceToken:deviceToken completion:nil];
}

+ (void)newDeviceToken:(NSData *)deviceToken completion:(void(^)(BOOL success))block
{
//    NSMutableDictionary *parameters = [[self identity] mutableDictionary];
//    parameters[MITDeviceTypeKey] = MITDeviceTypeApple;
//
//    if(deviceToken) {
//        parameters[@"device_token"] = [self stringFromToken:deviceToken];
//        parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
//    }
//
//    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"newDeviceToken" parameters:parameters];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {
//        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
//
//        if ([registerObject isKindOfClass:[NSDictionary class]]) {
//            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
//            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];
//        }
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            if (block) {
//                block(YES);
//            }
//        }];
//
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        DDLogError(@"device registration failed: %@", [error localizedDescription]);
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            if (block) {
//                block(NO);
//            }
//        }];
//    }];
//
//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (void)clearIdentity
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:MITDeviceIdKey];
    [userDefaults removeObjectForKey:MITPassCodeKey];

    // TODO (bskinner): Should this be removed as well?
    //[userDefaults removeObjectForKey:DeviceTokenKey];
    [userDefaults synchronize];
}

+ (MITIdentity *) identity {
	NSString *deviceId = [[[NSUserDefaults standardUserDefaults] objectForKey:MITDeviceIdKey] description];
	NSString *passKey = [[[NSUserDefaults standardUserDefaults] objectForKey:MITPassCodeKey] description];

	if(deviceId) {
		return [[MITIdentity alloc] initWithDeviceId:deviceId passKey:passKey];
	} else {
		return nil;
	}
}
@end


// Class not currently in use by anything. This will be used to
// help keep better track of the current device registration (both from the APNS
// and our API server).
// (bskinner - 2014.11.14)
static NSString* const MITDeviceIdentityDeviceTokenKey = @"DeviceToken";
static NSString* const MITDeviceIdentityDeviceIdentifierKey = @"DeviceIdentifier";
static NSString* const MITDeviceIdentityPasscodeKey = @"Passcode";

@implementation MITDeviceIdentity
@dynamic isRegistered;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        _deviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:DeviceTokenKey];
        _deviceIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:MITDeviceIdKey];
        _passcode = [[NSUserDefaults standardUserDefaults] stringForKey:MITPassCodeKey];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        if (aDecoder.allowsKeyedCoding) {
            _deviceToken = [aDecoder decodeObjectOfClass:[NSData class] forKey:MITDeviceIdentityDeviceTokenKey];
            _deviceIdentifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITDeviceIdentityDeviceIdentifierKey];
            _passcode = [aDecoder decodeObjectOfClass:[NSString class] forKey:MITDeviceIdentityPasscodeKey];
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (aCoder.allowsKeyedCoding) {
        [aCoder encodeObject:self.deviceToken forKey:MITDeviceIdentityDeviceTokenKey];
        [aCoder encodeObject:self.deviceIdentifier forKey:MITDeviceIdentityDeviceIdentifierKey];
        [aCoder encodeObject:self.passcode forKey:MITDeviceIdentityPasscodeKey];
    }
}

#pragma mark properties
- (BOOL)isRegistered
{
    return (self.deviceToken != nil);
}

- (BOOL)isEnabled
{
    return (BOOL)(self.isRegistered && self.passcode);
}

- (void)setDeviceToken:(NSData *)deviceToken
{
    [self setDeviceToken:deviceToken completion:nil];
}

- (void)setDeviceToken:(NSData *)deviceToken completion:(void(^)(NSError *error))block
{
    if (![_deviceToken isEqualToData:deviceToken]) {
        NSData *oldToken = _deviceToken;
        _deviceToken = [deviceToken copy];

        [self registerDeviceWithToken:self.deviceToken oldToken:oldToken completion:^(NSError* error) {
            if (block) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    block(error);
                }];
            }
        }];
    }
}

- (void)registerDevice:(void (^)(NSError *))completion
{
    [self registerDeviceWithToken:self.deviceToken oldToken:nil completion:completion];
}

- (void)registerDeviceWithToken:(NSData*)newToken oldToken:(NSData*)oldToken completion:(void(^)(NSError *error))block
{
    __weak MITDeviceIdentity *weakSelf = self;

    if (!newToken) {
        self.passcode = nil;
        self.deviceIdentifier = nil;
    } else if (oldToken && self.passcode) {
        [self updateRegisteredDeviceToken:newToken oldToken:oldToken completion:^(NSString *deviceIdentifier, NSString *passcode) {
            MITDeviceIdentity *blockSelf = weakSelf;
            blockSelf.deviceIdentifier = passcode;
            blockSelf.passcode = deviceIdentifier;

            if (block) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    block(nil);
                }];
            }
        } error:^(NSError *error) {
            MITDeviceIdentity *blockSelf = weakSelf;
            blockSelf.passcode = nil;
            blockSelf.deviceIdentifier = nil;

            if (block) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    block(error);
                }];
            }
        }];
    } else {
        [self registerNewDeviceWithToken:newToken completion:^(NSString *deviceIdentifier, NSString *passcode) {
            MITDeviceIdentity *blockSelf = weakSelf;
            blockSelf.deviceIdentifier = passcode;
            blockSelf.passcode = deviceIdentifier;

            if (block) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    block(nil);
                }];
            }
        } error:^(NSError *error) {
            MITDeviceIdentity *blockSelf = weakSelf;
            blockSelf.passcode = nil;
            blockSelf.deviceIdentifier = nil;

            if (block) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    block(error);
                }];
            }
        }];
    }
}

- (void)updateRegisteredDeviceToken:(NSData*)newToken oldToken:(NSData*)oldToken completion:(void(^)(NSString *deviceIdentifier, NSString *passcode))successBlock error:(void(^)(NSError *error))failureBlock
{
//    NSParameterAssert(oldToken);
//    NSAssert(self.deviceToken, @"deviceToken is nil, a valid token is required for device registration");
//
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{MITDeviceIdKey : self.deviceIdentifier,
//                                                                                      MITPassCodeKey : self.passcode,
//                                                                                      MITDeviceTypeKey : MITDeviceTypeApple}];
//    parameters[@"device_token"] = MITHexStringFromNSData(self.deviceToken);
//    parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleIdentifierKey];
//
//    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"newDeviceToken" parameters:parameters];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//
//    __weak MITDeviceIdentity *weakSelf = self;
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *deviceRegistration) {
//        MITDeviceIdentity *blockSelf = weakSelf;
//        if (!blockSelf) {
//            return;
//        } else if (![deviceRegistration isKindOfClass:[NSDictionary class]]) {
//            DDLogWarn(@"received invalid response for newDeviceToken command. Expected response object of type %@, got %@",NSStringFromClass([NSDictionary class]),NSStringFromClass([deviceRegistration class]));
//            return;
//        } else if (successBlock) {
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                successBlock(deviceRegistration[MITDeviceIdKey],deviceRegistration[MITPassCodeKey]);
//            }];
//        }
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        DDLogWarn(@"device registration failed: %@", [error localizedDescription]);
//        if (failureBlock) {
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                failureBlock(error);
//            }];
//        }
//    }];
//    
//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (void)registerNewDeviceWithToken:(NSData*)newToken completion:(void(^)(NSString *deviceIdentifier,NSString *passcode))successBlock error:(void(^)(NSError *error))failureBlock
{
//    NSAssert(self.deviceToken, @"deviceToken is nil, a valid token is required for device registration");
//
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    if (self.deviceIdentifier) {
//        parameters[MITDeviceIdKey] = self.deviceIdentifier;
//    }
//    if (self.passcode) {
//        parameters[MITPassCodeKey] = self.passcode;
//    }
//    parameters[MITDeviceTypeKey] = MITDeviceTypeApple;
//    parameters[@"device_token"] = MITHexStringFromNSData(self.deviceToken);
//    parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleIdentifierKey];
//
//    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"register" parameters:parameters];
//    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
//
//    __weak MITDeviceIdentity *weakSelf = self;
//    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *deviceRegistration) {
//        MITDeviceIdentity *blockSelf = weakSelf;
//        if (!blockSelf) {
//            return;
//        } else if (![deviceRegistration isKindOfClass:[NSDictionary class]]) {
//            DDLogWarn(@"received invalid response for newDeviceToken command. Expected response object of type %@, got %@",NSStringFromClass([NSDictionary class]),NSStringFromClass([deviceRegistration class]));
//            return;
//        } else if (successBlock) {
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                successBlock(deviceRegistration[MITDeviceIdKey],deviceRegistration[MITPassCodeKey]);
//            }];
//        }
//    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
//        DDLogWarn(@"device registration failed: %@", [error localizedDescription]);
//        if (failureBlock) {
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                failureBlock(error);
//            }];
//        }
//    }];
//
//    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

@end
