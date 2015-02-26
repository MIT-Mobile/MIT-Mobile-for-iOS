//#import <RestKit/RestKit.h>
#import <AFNetworking/AFNetworking.h>
@interface MITTouchstoneRequestOperation : AFHTTPRequestOperation
+ (void)setUserAgent:(NSString*)userAgent;
+ (NSString*)userAgent;

- (instancetype)initWithRequest:(NSURLRequest*)request;

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
@end
