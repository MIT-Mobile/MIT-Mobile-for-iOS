#import "MITTouchstoneRequestOperation.h"

@interface MITTouchstoneRequestOperation (MITMobileV3)

+ (NSURLRequest*)requestForEndpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters andRequestMethod:(NSString *)requestMethod;

@end