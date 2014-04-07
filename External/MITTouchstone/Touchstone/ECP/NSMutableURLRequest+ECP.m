#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneConstants.h"

static inline NSString* MITTouchstoneAcceptHeaderValue() {
    NSArray *acceptedTypes = @[@"q=1.0,application/json",
                               @"q=0.8,text/html",
                               MITECPMIMEType];
    return [acceptedTypes componentsJoinedByString:@"; "];
}

static inline NSString* MITTouchstonePAOSHeaderValue() {
    return [NSString stringWithFormat:@"ver=\"%@\"; \"%@\"",MITPAOSNamespaceURI,MITECPNamespaceURI];
}

@implementation NSURLRequest (ECP)
- (NSMutableURLRequest*)mutableCopyTouchstoneAdvertised;
{
    NSMutableURLRequest *request = [self mutableCopy];
    NSAssert([request isKindOfClass:[NSMutableURLRequest class]],@"fatal error: failed to create a mutable copy of %@",self);
    
    request.HTTPShouldHandleCookies = YES;
    [request setValue:MITTouchstoneAcceptHeaderValue() forHTTPHeaderField:@"Accept"];
    [request setValue:MITTouchstonePAOSHeaderValue() forHTTPHeaderField:MITECPPAOSHeaderName];
    return request;
}

@end

@implementation NSMutableURLRequest (ECP)
+ (instancetype)touchstoneRequestWithURL:(NSURL *)URL
                             cachePolicy:(NSURLRequestCachePolicy)cachePolicy
                         timeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL
                                                         cachePolicy:cachePolicy
                                                     timeoutInterval:timeoutInterval];
    request.HTTPShouldHandleCookies = YES;
    
    [request setValue:MITTouchstoneAcceptHeaderValue() forHTTPHeaderField:@"Accept"];
    [request setValue:MITTouchstonePAOSHeaderValue() forHTTPHeaderField:MITECPPAOSHeaderName];
    
    return request;
}

+ (instancetype)touchstoneRequestWithURL:(NSURL*)URL
{
    NSMutableURLRequest *request = [[self alloc] initWithURL:URL];
    request.HTTPShouldHandleCookies = YES;
    
    [request setValue:MITTouchstoneAcceptHeaderValue() forHTTPHeaderField:@"Accept"];
    [request setValue:MITTouchstonePAOSHeaderValue() forHTTPHeaderField:MITECPPAOSHeaderName];
    
    return request;
}

@end
