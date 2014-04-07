#import <Foundation/Foundation.h>

@interface NSURLRequest (ECP)
- (NSMutableURLRequest*)mutableCopyTouchstoneAdvertised;
@end

@interface NSMutableURLRequest (ECP)
+ (instancetype)touchstoneRequestWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval;
+ (instancetype)touchstoneRequestWithURL:(NSURL*)URL;
@end
