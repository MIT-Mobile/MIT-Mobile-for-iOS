#import "MITDeviceRegistration.h"
#import "MobileRequestOperation.h"

static NSString * const MITDeviceTypeKey = @"device_type";
static NSString * const MITDeviceTypeApple = @"apple";

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
	
+ (void)registerNewDeviceWithToken: (NSData *)deviceToken {
	NSMutableDictionary *parameters = [@{MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];
	if(deviceToken) {		
		[parameters setObject:[self stringFromToken:deviceToken] forKey:@"device_token"];
		[parameters setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"app_id"];
	}		
    
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"push"
                                                                              command:@"register"
                                                                           parameters:parameters];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            DDLogError(@"device registration failed: %@", error);
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
            
            if ([jsonResult isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonDict = jsonResult;
                [[NSUserDefaults standardUserDefaults] setObject:jsonDict[MITDeviceIdKey] forKey:MITDeviceIdKey];
                [[NSUserDefaults standardUserDefaults] setObject:jsonDict[MITPassCodeKey] forKey:MITPassCodeKey];
            }
        }
    };

    [[NSOperationQueue mainQueue] addOperation:request];
}

+ (void)registerDeviceWithToken:(NSData*)deviceToken registered:(void (^)(MITIdentity *identity,NSError *error))block
{
	NSMutableDictionary *parameters = [@{MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];

	if(deviceToken) {
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}

    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"push"
                                                                              command:@"register"
                                                                           parameters:parameters];

    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (!error) {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];

            if ([jsonResult isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonDict = jsonResult;

                [[NSUserDefaults standardUserDefaults] setObject:jsonDict[MITDeviceIdKey]
                                                          forKey:MITDeviceIdKey];
                [[NSUserDefaults standardUserDefaults] setObject:jsonDict[MITPassCodeKey]
                                                          forKey:MITPassCodeKey];
            } else {
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:NSURLErrorBadServerResponse
                                        userInfo:@{NSLocalizedDescriptionKey : @"unable to register device, invalid response from server"}];
            }
        }

        if (block) {
            block([MITDeviceRegistration identity], error);
        }
    };

    [[NSOperationQueue mainQueue] addOperation:request];
}

+ (void)newDeviceToken:(NSData *)deviceToken {
	NSMutableDictionary *parameters = [[self identity] mutableDictionary];
	parameters[MITDeviceTypeKey] = MITDeviceTypeApple;

    if(deviceToken) {
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}
    
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"push"
                                                                              command:@"newDeviceToken"
                                                                           parameters:parameters];

    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {

        } else {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
            
            if ([jsonResult isKindOfClass:[NSDictionary class]]) {
                NSDictionary *jsonDict = jsonResult;
                [[NSUserDefaults standardUserDefaults] setObject:[jsonDict objectForKey:MITDeviceIdKey] forKey:MITDeviceIdKey];
                [[NSUserDefaults standardUserDefaults] setObject:[jsonDict objectForKey:MITPassCodeKey] forKey:MITPassCodeKey];
            }
        }
    };

    [[NSOperationQueue mainQueue] addOperation:request];
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
