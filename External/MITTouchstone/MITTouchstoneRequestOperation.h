#import "AFHTTPRequestOperation.h"

@interface MITTouchstoneRequestOperation : AFHTTPRequestOperation
+ (void)setUserAgent:(NSString*)userAgent;
+ (NSString*)userAgent;

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
@end
