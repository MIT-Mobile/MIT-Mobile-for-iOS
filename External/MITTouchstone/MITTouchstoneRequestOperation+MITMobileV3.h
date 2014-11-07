#import "MITTouchstoneRequestOperation.h"

extern NSString * const MITTouchstoneRequestOperationRequestMethodGET;
extern NSString * const MITTOuchstoneRequestOperationRequestMethodPOST;

@interface MITTouchstoneRequestOperation (MITMobileV3)

+ (NSURLRequest*)requestForEndpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters andRequestMethod:(NSString *)requestMethod;

@end