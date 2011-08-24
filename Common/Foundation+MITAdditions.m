#import "Foundation+MITAdditions.h"

@implementation NSURL (MITAdditions)

+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path {
    return [NSURL internalURLWithModuleTag:tag path:path query:nil];
}

+ (NSURL *)internalURLWithModuleTag:(NSString *)tag path:(NSString *)path query:(NSString *)query {
    if ([path rangeOfString:@"/"].location != 0) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    if ([query length] > 0) {
        path = [path stringByAppendingFormat:@"?%@", query];
    }
    NSURL *url = [[NSURL alloc] initWithScheme:MITInternalURLScheme host:tag path:path];
    return [url autorelease];
}

@end

@implementation NSMutableString (MITAdditions)

- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)options {
    assert([targets count] == [replacements count]);
    NSInteger i = 0;
    for (NSString *target in targets) {
        [self replaceOccurrencesOfString:target withString:[replacements objectAtIndex:i] options:options range:NSMakeRange(0, [self length])];
        i++;
    }
}

@end

@implementation NSString (MITAdditions)

- (NSString *)substringToMaxIndex:(NSUInteger)to {
	NSUInteger maxLength = [self length] - 1;
	return [self substringToIndex:(to > maxLength) ? maxLength : to];
}

@end


// RFC 3986 reserved characters
static NSString *rfc6986_Reserved = @":/?#[]@!$&'()*+,;=";
// RFC 1738 unsafe characters
static NSString *rfc1738_Unsafe = @"<>\"#%{}|\\^~`";

@implementation NSString (MITAdditions_URLEncoding)
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


@implementation NSString (MITAdditions_HTMLEntity)
- (NSString *)stringByDecodingXMLEntities {
    NSUInteger strLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&"
                                      options:NSLiteralSearch].location;
    
    if (ampIndex == NSNotFound) {
        return self;
    }
    
    NSMutableString *result = [NSMutableString stringWithCapacity:strLength];
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    while (![scanner isAtEnd]) {
        NSString *nonEntityString = nil;
        
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        
        if ([scanner scanString:@"&amp;" intoString:NULL])
        {
            [result appendString:@"&"];
        }
        else if ([scanner scanString:@"&apos;" intoString:NULL])
        {
            [result appendString:@"'"];
        }
        else if ([scanner scanString:@"&quot;" intoString:NULL])
        {
            [result appendString:@"\""];
        }
        else if ([scanner scanString:@"&lt;" intoString:NULL])
        {
            [result appendString:@"<"];
        }
        else if ([scanner scanString:@"&gt;" intoString:NULL])
        {
            [result appendString:@">"];
        }
        else if ([scanner scanString:@"&#" intoString:NULL])
        {
            BOOL readNumber;
            unsigned charCode;
            NSString *hexIdentifier = @"";
            
            if ([scanner scanString:@"x" intoString:&hexIdentifier]) {
                readNumber = [scanner scanHexInt:&charCode];
            }
            else {
                readNumber = [scanner scanInt:(int*)&charCode];
            }
            
            if (readNumber)
            {
                [result appendFormat:@"%C", charCode];
            }
            else
            {
                NSString *unknownEntity = @"";
                
                [scanner scanUpToString:@";" intoString:&unknownEntity];
                [result appendFormat:@"&#%@%@;", hexIdentifier, unknownEntity];
                
                NSLog(@"Expected numeric character entity but got &#%@%@;", hexIdentifier, unknownEntity);
            }
            
            [scanner scanString:@";" intoString:NULL];
        }
        else
        {
            NSString *unknownEntity = @"";
            NSString *semicolon = @"";
            
            [scanner scanUpToString:@";" intoString:&unknownEntity];
            [scanner scanString:@";" intoString:&semicolon];
            
            [result appendFormat:@"%@%@", unknownEntity, semicolon];
            NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
        }
    }

    return result;
}
@end
