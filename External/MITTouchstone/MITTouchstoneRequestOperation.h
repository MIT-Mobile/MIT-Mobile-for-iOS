#import <RestKit/RestKit.h>

@interface MITTouchstoneRequestOperation : RKHTTPRequestOperation
+ (void)setUserAgent:(NSString*)userAgent;
+ (NSString*)userAgent;

- (instancetype)initWithRequest:(NSURLRequest*)request;

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
@end
