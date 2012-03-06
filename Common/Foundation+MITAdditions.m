#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
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

- (BOOL)containsSubstring:(NSString*)string options:(NSStringCompareOptions)mask
{
    NSRange substringRange = [self rangeOfString:string
                                         options:mask];
    
    return (substringRange.location != NSNotFound);
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
typedef struct {
    char *entityName;
    char *entityCode;
} htmlEntity_t;

- (NSString*)stringByConvertingHTMLNamedEntities
{
    static htmlEntity_t htmlEntities[] = {
        {"&Aacute;","&#x00C1;"}, {"&aacute;","&#x00E1;"},   {"&Acirc;","&#x00C2;"},
        {"&acirc;","&#x00E2;"},  {"&acute;","&#x00B4;"},    {"&AElig;","&#x00C6;"},
        {"&aelig;","&#x00E6;"},  {"&Agrave;","&#x00C0;"},   {"&agrave;","&#x00E0;"},
        {"&alefsym;","&#x2135;"},{"&Alpha;","&#x0391;"},    {"&alpha;","&#x03B1;"},
        {"&amp;","&#x0026;"},    {"&and;","&#x2227;"},      {"&ang;","&#x2220;"},
        {"&apos;","&#x0027;"},   {"&Aring;","&#x00C5;"},    {"&aring;","&#x00E5;"},
        {"&asymp;","&#x2248;"},  {"&Atilde;","&#x00C3;"},   {"&atilde;","&#x00E3;"},
        {"&Auml;","&#x00C4;"},   {"&auml;","&#x00E4;"},     {"&bdquo;","&#x201E;"},
        {"&Beta;","&#x0392;"},   {"&beta;","&#x03B2;"},     {"&brvbar;","&#x00A6;"},
        {"&bull;","&#x2022;"},   {"&cap;","&#x2229;"},      {"&Ccedil;","&#x00C7;"},
        {"&ccedil;","&#x00E7;"}, {"&cedil;","&#x00B8;"},    {"&cent;","&#x00A2;"},
        {"&Chi;","&#x03A7;"},    {"&chi;","&#x03C7;"},      {"&circ;","&#x02C6;"},
        {"&clubs;","&#x2663;"},  {"&cong;","&#x2245;"},     {"&copy;","&#x00A9;"},
        {"&crarr;","&#x21B5;"},  {"&cup;","&#x222A;"},      {"&curren;","&#x00A4;"},
        {"&dagger;","&#x2020;"}, {"&Dagger;","&#x2021;"},   {"&darr;","&#x2193;"},
        {"&dArr;","&#x21D3;"},   {"&deg;","&#x00B0;"},      {"&Delta;","&#x0394;"},
        {"&delta;","&#x03B4;"},  {"&diams;","&#x2666;"},    {"&divide;","&#x00F7;"},
        {"&Eacute;","&#x00C9;"}, {"&eacute;","&#x00E9;"},   {"&Ecirc;","&#x00CA;"},
        {"&ecirc;","&#x00EA;"},  {"&Egrave;","&#x00C8;"},   {"&egrave;","&#x00E8;"},
        {"&empty;","&#x2205;"},  {"&emsp;","&#x2003;"},     {"&ensp;","&#x2002;"},
        {"&Epsilon;","&#x0395;"},{"&epsilon;","&#x03B5;"},  {"&equiv;","&#x2261;"},
        {"&Eta;","&#x0397;"},    {"&eta;","&#x03B7;"},      {"&ETH;","&#x00D0;"},
        {"&eth;","&#x00F0;"},    {"&Euml;","&#x00CB;"},     {"&euml;","&#x00EB;"},
        {"&euro;","&#x20AC;"},   {"&exist;","&#x2203;"},    {"&fnof;","&#x0192;"},
        {"&forall;","&#x2200;"}, {"&frac12;","&#x00BD;"},   {"&frac14;","&#x00BC;"},
        {"&frac34;","&#x00BE;"}, {"&frasl;","&#x2044;"},    {"&Gamma;","&#x0393;"},
        {"&gamma;","&#x03B3;"},  {"&ge;","&#x2265;"},       {"&gt;","&#x003E;"},
        {"&harr;","&#x2194;"},   {"&hArr;","&#x21D4;"},     {"&hearts;","&#x2665;"},
        {"&hellip;","&#x2026;"}, {"&Iacute;","&#x00CD;"},   {"&iacute;","&#x00ED;"},
        {"&Icirc;","&#x00CE;"},  {"&icirc;","&#x00EE;"},    {"&iexcl;","&#x00A1;"},
        {"&Igrave;","&#x00CC;"}, {"&igrave;","&#x00EC;"},   {"&image;","&#x2111;"},
        {"&infin;","&#x221E;"},  {"&int;","&#x222B;"},      {"&Iota;","&#x0399;"},
        {"&iota;","&#x03B9;"},   {"&iquest;","&#x00BF;"},   {"&isin;","&#x2208;"},
        {"&Iuml;","&#x00CF;"},   {"&iuml;","&#x00EF;"},     {"&Kappa;","&#x039A;"},
        {"&kappa;","&#x03BA;"},  {"&Lambda;","&#x039B;"},   {"&lambda;","&#x03BB;"},
        {"&lang;","&#x2329;"},   {"&laquo;","&#x00AB;"},    {"&larr;","&#x2190;"},
        {"&lArr;","&#x21D0;"},   {"&lceil;","&#x2308;"},    {"&ldquo;","&#x201C;"},
        {"&le;","&#x2264;"},     {"&lfloor;","&#x230A;"},   {"&lowast;","&#x2217;"},
        {"&loz;","&#x25CA;"},    {"&lrm;","&#x200E;"},      {"&lsaquo;","&#x2039;"},
        {"&lsquo;","&#x2018;"},  {"&lt;","&#x003C;"},       {"&macr;","&#x00AF;"},
        {"&mdash;","&#x2014;"},  {"&micro;","&#x00B5;"},    {"&middot;","&#x00B7;"},
        {"&minus;","&#x2212;"},  {"&Mu;","&#x039C;"},       {"&mu;","&#x03BC;"},
        {"&nabla;","&#x2207;"},  {"&nbsp;","&#x00A0;"},     {"&ndash;","&#x2013;"},
        {"&ne;","&#x2260;"},     {"&ni;","&#x220B;"},       {"&not;","&#x00AC;"},
        {"&notin;","&#x2209;"},  {"&nsub;","&#x2284;"},     {"&Ntilde;","&#x00D1;"},
        {"&ntilde;","&#x00F1;"}, {"&Nu;","&#x039D;"},       {"&nu;","&#x03BD;"},
        {"&Oacute;","&#x00D3;"}, {"&oacute;","&#x00F3;"},   {"&Ocirc;","&#x00D4;"},
        {"&ocirc;","&#x00F4;"},  {"&OElig;","&#x0152;"},    {"&oelig;","&#x0153;"},
        {"&Ograve;","&#x00D2;"}, {"&ograve;","&#x00F2;"},   {"&oline;","&#x203E;"},
        {"&Omega;","&#x03A9;"},  {"&omega;","&#x03C9;"},    {"&Omicron;","&#x039F;"},
        {"&omicron;","&#x03BF;"},{"&oplus;","&#x2295;"},    {"&or;","&#x2228;"},
        {"&ordf;","&#x00AA;"},   {"&ordm;","&#x00BA;"},     {"&Oslash;","&#x00D8;"},
        {"&oslash;","&#x00F8;"}, {"&Otilde;","&#x00D5;"},   {"&otilde;","&#x00F5;"},
        {"&otimes;","&#x2297;"}, {"&Ouml;","&#x00D6;"},     {"&ouml;","&#x00F6;"},
        {"&para;","&#x00B6;"},   {"&part;","&#x2202;"},     {"&permil;","&#x2030;"},
        {"&perp;","&#x22A5;"},   {"&Phi;","&#x03A6;"},      {"&phi;","&#x03C6;"},
        {"&Pi;","&#x03A0;"},     {"&pi;","&#x03C0;"},       {"&piv;","&#x03D6;"},
        {"&plusmn;","&#x00B1;"}, {"&pound;","&#x00A3;"},    {"&prime;","&#x2032;"},
        {"&Prime;","&#x2033;"},  {"&prod;","&#x220F;"},     {"&prop;","&#x221D;"},
        {"&Psi;","&#x03A8;"},    {"&psi;","&#x03C8;"},      {"&quot;","&#x0022;"},
        {"&radic;","&#x221A;"},  {"&rang;","&#x232A;"},     {"&raquo;","&#x00BB;"},
        {"&rarr;","&#x2192;"},   {"&rArr;","&#x21D2;"},     {"&rceil;","&#x2309;"},
        {"&rdquo;","&#x201D;"},  {"&real;","&#x211C;"},     {"&reg;","&#x00AE;"},
        {"&rfloor;","&#x230B;"}, {"&Rho;","&#x03A1;"},      {"&rho;","&#x03C1;"},
        {"&rlm;","&#x200F;"},    {"&rsaquo;","&#x203A;"},   {"&rsquo;","&#x2019;"},
        {"&sbquo;","&#x201A;"},  {"&Scaron;","&#x0160;"},   {"&scaron;","&#x0161;"},
        {"&sdot;","&#x22C5;"},   {"&sect;","&#x00A7;"},     {"&shy;","&#x00AD;"},
        {"&Sigma;","&#x03A3;"},  {"&sigma;","&#x03C3;"},    {"&sigmaf;","&#x03C2;"},
        {"&sim;","&#x223C;"},    {"&spades;","&#x2660;"},   {"&sub;","&#x2282;"},
        {"&sube;","&#x2286;"},   {"&sum;","&#x2211;"},      {"&sup1;","&#x00B9;"},
        {"&sup2;","&#x00B2;"},   {"&sup3;","&#x00B3;"},     {"&sup;","&#x2283;"},
        {"&supe;","&#x2287;"},   {"&szlig;","&#x00DF;"},    {"&Tau;","&#x03A4;"},
        {"&tau;","&#x03C4;"},    {"&there4;","&#x2234;"},   {"&Theta;","&#x0398;"},
        {"&theta;","&#x03B8;"},  {"&thetasym;","&#x03D1;"}, {"&thinsp;","&#x2009;"},
        {"&THORN;","&#x00DE;"},  {"&thorn;","&#x00FE;"},    {"&tilde;","&#x02DC;"},
        {"&times;","&#x00D7;"},  {"&trade;","&#x2122;"},    {"&Uacute;","&#x00DA;"},
        {"&uacute;","&#x00FA;"}, {"&uarr;","&#x2191;"},     {"&uArr;","&#x21D1;"},
        {"&Ucirc;","&#x00DB;"},  {"&ucirc;","&#x00FB;"},    {"&Ugrave;","&#x00D9;"},
        {"&ugrave;","&#x00F9;"}, {"&uml;","&#x00A8;"},      {"&upsih;","&#x03D2;"},
        {"&Upsilon;","&#x03A5;"},{"&upsilon;","&#x03C5;"},  {"&Uuml;","&#x00DC;"},
        {"&uuml;","&#x00FC;"},   {"&weierp;","&#x2118;"},   {"&Xi;","&#x039E;"},
        {"&xi;","&#x03BE;"},     {"&Yacute;","&#x00DD;"},   {"&yacute;","&#x00FD;"},
        {"&yen;","&#x00A5;"},    {"&yuml;","&#x00FF;"},     {"&Yuml;","&#x0178;"},
        {"&Zeta;","&#x0396;"},   {"&zeta;","&#x03B6;"},     {"&zwj;","&#x200D;"},
        {"&zwnj;","&#x200C;"},   {NULL,NULL}};
    
    NSMutableString *replString = [NSMutableString stringWithCapacity:([self length] * 1.25)];
    [replString setString:self];
    
    htmlEntity_t *entity = htmlEntities;
    while (entity->entityName != NULL) {
        NSUInteger entities = [replString replaceOccurrencesOfString:[NSString stringWithUTF8String:entity->entityName]
                                                          withString:[NSString stringWithUTF8String:entity->entityCode]
                                                             options:0
                                                               range:NSMakeRange(0, [replString length])];
        
        if (entities > 0) {
            DLog(@"Replaced %lu of %s -> %s", (unsigned long)entities, entity->entityName, entity->entityCode);
        }
        
        ++entity;
    }
    
    return replString;
}

- (NSString *)stringByDecodingXMLEntities {
    NSUInteger ampIndex = [self rangeOfString:@"&"
                                      options:NSLiteralSearch].location;
    
    if (ampIndex == NSNotFound) {
        return [NSString stringWithString:self];
    }
    
    // May or may not have numeric character entities at this point
    // so run it through the check anyway
    NSString *searchString = [self stringByConvertingHTMLNamedEntities];
    xmlParserCtxtPtr parserContext = htmlNewParserCtxt();
    htmlCtxtUseOptions(parserContext,
                       (HTML_PARSE_RECOVER |
                        HTML_PARSE_NOERROR |
                        HTML_PARSE_NOWARNING));
    xmlChar *convertedString = xmlStringDecodeEntities(parserContext,
                                                       (xmlChar*)[searchString UTF8String],
                                                       XML_SUBSTITUTE_BOTH,
                                                       0,
                                                       0,
                                                       0);
    
    NSString *result = [NSString stringWithUTF8String:(char*)convertedString];
    xmlFree(convertedString);
    xmlFreeParserCtxt(parserContext);
    
    return result;
}
@end

@implementation UIDevice (MITAdditions)
- (NSString*)sysInfoByName:(NSString*)typeSpecifier
{
    const char *typeString = [typeSpecifier UTF8String];
    size_t size = 0;
    int status = sysctlbyname(typeString, NULL, &size, NULL, 0);

    if (status) {
        ELog(@"sysctl '%@' failed: %s", typeSpecifier, strerror(status));
        return nil;
    }
    
    char *result = malloc(size);
    memset(result, 0, size);
    status = sysctlbyname(typeString, result, &size, NULL, 0);
    if (status) {
        ELog(@"sysctl '%@' failed: %s", typeSpecifier, strerror(status));
        return nil;
    }
    
    NSString *resultString = [NSString stringWithCString:result
                                                encoding:NSUTF8StringEncoding];
    free(result);
    return resultString;
}

- (NSString*)cpuType
{
    cpu_type_t cpuType = CPU_TYPE_ANY;
    cpu_subtype_t cpuSubtype = CPU_SUBTYPE_MULTIPLE;
    
    size_t size = sizeof(cpu_type_t);
    sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0);
    
    size = sizeof(cpu_subtype_t);
    sysctlbyname("hw.cpusubtype", &cpuSubtype, &size, NULL, 0);
    
    
    if (cpuType == CPU_TYPE_ARM) {
        NSMutableString *cpuString = [NSMutableString stringWithString:@"armv"];
        switch (cpuSubtype)
        {
            case CPU_SUBTYPE_ARM_V4T:
                [cpuString appendString:@"4t"];
                break;
            case CPU_SUBTYPE_ARM_V5TEJ:
                [cpuString appendString:@"5tej"];
                break;
            case CPU_SUBTYPE_ARM_V6:
                [cpuString appendString:@"6"];
                break;
            case CPU_SUBTYPE_ARM_V7:
                [cpuString appendString:@"7"];
                break;
            case CPU_SUBTYPE_ARM_V7F:
                [cpuString appendString:@"7f"];
                break;
            case CPU_SUBTYPE_ARM_V7K:
                [cpuString appendString:@"7k"];
                break;
        }
        
        return cpuString;
    } else if (cpuType == CPU_TYPE_X86_64) {
        return @"x86_64";
    } else if (cpuType == CPU_TYPE_X86) {
        return @"i386";
    } else {
        return @"Unknown";
    }
}
@end
