#import "MITDeviceRegistration.h"
#import "MITTouchstoneRequestOperation+LegacyCompatibility.h"

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
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}		

    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"register" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {
        if ([registerObject isKindOfClass:[NSDictionary class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        DDLogError(@"device registration failed: %@", [error localizedDescription]);
    }];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (void)registerDeviceWithToken:(NSData*)deviceToken registered:(void (^)(MITIdentity *identity,NSError *error))block
{
	NSMutableDictionary *parameters = [@{MITDeviceTypeKey : MITDeviceTypeApple} mutableCopy];

	if(deviceToken) {
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}

    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"register" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {

        if ([registerObject isKindOfClass:[NSDictionary class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];

            if (block) {
                block([MITDeviceRegistration identity],nil);
            }
        } else {
            if (block) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                     code:NSURLErrorBadServerResponse
                                                 userInfo:@{NSLocalizedDescriptionKey : @"unable to register device, invalid response from server"}];
                block([MITDeviceRegistration identity], error);
            }
        }

    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        if (block) {
            block([MITDeviceRegistration identity], error);
        }
    }];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (void)newDeviceToken:(NSData *)deviceToken {
	NSMutableDictionary *parameters = [[self identity] mutableDictionary];
	parameters[MITDeviceTypeKey] = MITDeviceTypeApple;

    if(deviceToken) {
		parameters[@"device_token"] = [self stringFromToken:deviceToken];
		parameters[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}

    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"newDeviceToken" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registerObject) {
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];

        if ([registerObject isKindOfClass:[NSDictionary class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:DeviceTokenKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITDeviceIdKey] forKey:MITDeviceIdKey];
            [[NSUserDefaults standardUserDefaults] setObject:registerObject[MITPassCodeKey] forKey:MITPassCodeKey];
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        DDLogError(@"device registration failed: %@", [error localizedDescription]);
    }];

    [[NSOperationQueue mainQueue] addOperation:requestOperation];
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
