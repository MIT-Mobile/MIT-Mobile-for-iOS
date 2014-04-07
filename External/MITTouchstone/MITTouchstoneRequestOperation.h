#import <RestKit/RKHTTPRequestOperation.h>

@interface MITTouchstoneRequestOperation : RKHTTPRequestOperation
+ (void)setUserAgent:(NSString*)userAgent;
+ (NSString*)userAgent;

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
@end
