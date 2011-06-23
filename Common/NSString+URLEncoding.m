#import "NSString+URLEncoding.h"

// RFC 3986 reserved characters
static NSString *rfc6986_Reserved = @":/?#[]@!$&'()*+,;=";

// RFC 1738 unsafe characters
static NSString *rfc1738_Unsafe = @"<>\"#%{}|\\^~`";

@implementation NSString (URLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    NSString *forceEscapedCharacters = [rfc6986_Reserved stringByAppendingString:rfc1738_Unsafe];
    NSString *encodedString =  (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef)self,
                                                                                  NULL,
                                                                                  (CFStringRef)forceEscapedCharacters,
                                                                                  CFStringConvertNSStringEncodingToEncoding(encoding));
    return [encodedString autorelease];
}

- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding {
    NSString *decodedString = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                 (CFStringRef)self,
                                                                                                 NULL,
                                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding));
    return [decodedString autorelease];
}
@end
