#import "NSString+URLEncode.h"

// RFC 3986 reserved characters
static NSString *rfc6986_Reserved = @":/?#[]@!$&'()*+,;=";

// RFC 1738 unsafe characters
static NSString *rfc1738_Unsafe = @"<>\"#%{}|\\^~`";

@implementation NSString (MITURLEncoding)
- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding useFormURLEncoded:(BOOL)formUrlEncoded {
    NSString *forceEscapedCharacters = [rfc6986_Reserved stringByAppendingString:rfc1738_Unsafe];
    NSString *stringToEncode = self;
    
    if (formUrlEncoded) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\x0A|\x0D|\x0D\x0A)"
                                                                               options:0
                                                                                 error:NULL];
        stringToEncode = [regex stringByReplacingMatchesInString:self
                                                         options:0
                                                           range:NSMakeRange(0, [self length])
                                                    withTemplate:@"\x0D\x0A"];
    }
    
    NSString *encodedString =  (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef)stringToEncode,
                                                                                  (formUrlEncoded ? CFSTR(" ") : NULL),
                                                                                  (CFStringRef)forceEscapedCharacters,
                                                                                  CFStringConvertNSStringEncodingToEncoding(encoding));
    [encodedString autorelease];
    
    if (formUrlEncoded) {
        encodedString = [encodedString stringByReplacingOccurrencesOfString:@" "
                                                                 withString:@"+"];
    }
                                   
    return encodedString;
}

- (NSString*)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
    return [self urlEncodeUsingEncoding:encoding useFormURLEncoded:NO];
}

- (NSString*)urlDecodeUsingEncoding:(NSStringEncoding)encoding {
    NSString *decodedString = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                 (CFStringRef)self,
                                                                                                 NULL,
                                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding));
    return [decodedString autorelease];
}
@end
