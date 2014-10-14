#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>
#include <libxml/HTMLtree.h>
#include <libxml/xpath.h>
#import "Foundation+MITAdditions.h"

#pragma mark Error Domains
NSString * const MITXMLErrorDomain = @"MITXMLError";

#pragma mark Helper Functions
inline BOOL MITCGFloatIsEqual(CGFloat f0, CGFloat f1)
{
    return (fabs(((double)f0) - ((double)f1)) <= CGFLOAT_EPSILON);
}

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
    
    return [[NSURL alloc] initWithScheme:MITInternalURLScheme
                                    host:tag
                                    path:path];
}

- (NSDictionary*)queryDictionary
{
    NSArray *queryParameters = [[self query] componentsSeparatedByString:@"&"];
    
    if (![queryParameters count]) {
        return nil;
    }
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [queryParameters enumerateObjectsUsingBlock:^(NSString *queryPair, NSUInteger idx, BOOL *stop) {
        NSArray *parameter = [queryPair componentsSeparatedByString:@"="];
        
        if ([parameter count] == 1) {
            // This is a singlet parameter. Mark this using [NSNull null] for now
            parameters[parameter[0]] = [NSNull null];
        } else if ([parameter count] == 2) {
            parameters[parameter[0]] = parameter[1];
        }
    }];
    
    return parameters;
}

@end

@implementation NSArray (MITAdditions)
- (NSArray*)arrayByMappingObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block
{
    return [self mapObjectsUsingBlock:block];
}

- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger idx))block {
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:block(obj, idx)];
    }];

    return result;
}
@end

@implementation NSSet (MITAdditions)

- (NSSet *)mapObjectsUsingBlock:(id (^)(id obj))block {
    NSMutableSet *result = [NSMutableSet setWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [result addObject:block(obj)];
    }];
    return result;
}

@end

@implementation NSMutableString (MITAdditions)
- (void)replaceOccurrencesOfStrings:(NSArray *)targets withStrings:(NSArray *)replacements options:(NSStringCompareOptions)opts {
    if ([targets count] != [replacements count]) {
        @throw NSInvalidArgumentException;
    } else {
        [targets enumerateObjectsUsingBlock:^(NSString *target, NSUInteger idx, BOOL *stop) {
            [self replaceOccurrencesOfString:target
                                  withString:replacements[idx]
                                     options:opts
                                       range:NSMakeRange(0, [self length])];
        }];
    }
}
@end

@implementation NSString (MITAdditions)
- (BOOL)containsSubstring:(NSString*)string options:(NSStringCompareOptions)mask
{
    NSRange substringRange = [self rangeOfString:string
                                         options:mask];
    
    return (substringRange.location != NSNotFound);
}

- (NSString*)stringBySearchNormalization {
    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

    NSString *kdNormalizedString = [[self lowercaseString] decomposedStringWithCompatibilityMapping];
    NSArray *tokens = [kdNormalizedString componentsSeparatedByCharactersInSet:characterSet];
    return [tokens componentsJoinedByString:@""];
}

- (NSString*)stringBySanitizingHTMLFragmentWithPermittedElementNames:(NSArray*)tagNames error:(NSError**)error
{
    static NSString const *fragmentRootXpathExpression = @"/html/body/p/node()";

    if ([self length] == 0) {
        return [self copy];
    }

    // variables for the final returned string
    // and any libxml pointers which need to be cleaned up
    // prior to returning. These are here so clang won't
    // complain about uninitialized (or other potentially
    // nasty issues) if/when we hit a error
    NSString *resultString = nil;
    xmlDocPtr document = NULL;
    xmlXPathContextPtr xpathContext = NULL;
    xmlXPathObjectPtr xpathResult = NULL;

    // Needs to be free()'d in the cleanup section!
    xmlChar const *xpathExpression = xmlCharStrdup([fragmentRootXpathExpression cStringUsingEncoding:NSUTF8StringEncoding]);

    // Setup the LibXML HTML document. Since the string we are sanitizing
    // should be an HTML fragment, LibXML will not happily parse it. In order
    // to get everything to work, the fragment needs to be rooted (at a minimum)
    // at "<html><body>$fragment...". An additional requirement is that TEXT
    // nodes *must* have a direct parent Element so the '<p>' tag is being used
    // as a catch-all for any TEXT (or CDATA) nodes.
    NSString *htmlFragment = nil;
    
    // Since news decided to start surrounding things with 'p' tags...
    if ([self hasPrefix:@"<p>"]) {
        htmlFragment = [NSString stringWithFormat:@"<html><body>%@</body></html>",self];
    } else {
        htmlFragment = [NSString stringWithFormat:@"<html><body><p>%@</p></body></html>",self];
    }
    
    NSData *stringData = [htmlFragment dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger parserOptions = (HTML_PARSE_NONET |
                               HTML_PARSE_RECOVER |
                               HTML_PARSE_NOWARNING |
                               HTML_PARSE_NODEFDTD);
    document = htmlReadMemory([stringData bytes], [stringData length], "", NULL, parserOptions);
    if (!document) {
        DDLogWarn(@"failed to create xml document from HTML string");
        goto error;
    }

    xpathContext = xmlXPathNewContext(document);
    if (!xpathContext) {
        DDLogWarn(@"failed to create xpath context");
        goto error;
    }
    
    // Evaluate the XPath and pick out the first node we find. This is to
    //  prevent us from causing problems by removing the <html>,<body>, and
    //  <p> elements (they should be ignored by the tree-walker).
    // The fragmentRootXpathExpression should drop us right at the first
    //  child of the <p> element.
    xpathResult = xmlXPathEvalExpression(xpathExpression, xpathContext);
    if (!xpathResult) {
        DDLogVerbose(@"failed to evalulate path '%@'",fragmentRootXpathExpression);
        goto error;
    } else if (xmlXPathNodeSetIsEmpty(xpathResult->nodesetval)) {
        DDLogVerbose(@"no nodes found matching path '%@'",fragmentRootXpathExpression);
        goto error;
    } else {
        xmlNodePtr currentNode = xmlXPathNodeSetItem(xpathResult->nodesetval,0);

        while (currentNode) {
            xmlNodePtr nextNode = NULL;
            BOOL shouldUnlinkNode = NO;

            switch (currentNode->type) {
                case XML_ELEMENT_NODE: {
                    NSString *nodeName = [[NSString alloc] initWithBytes:currentNode->name
                                                                  length:xmlStrlen(currentNode->name)
                                                                encoding:NSUTF8StringEncoding];
                    if (![tagNames containsObject:nodeName]) {
                        // This node is not allowed! Migrate all of it's children up one level
                        // in order to prepare for deletion. The operation should looks something like:
                        //  parent                      parent
                        //    |                 -->       |
                        //  current->s0->..->sn         current->c0->..->cn->s0->..->sn
                        //    |
                        //    c0->..->cn
                        //
                        //  We don't need to worry about unlinking anything here since xmlAddNextSibling
                        //  should automatically handle it for us (if needed). This also sets shouldUnlinkNode
                        //  to YES so currentNode will be unlinked at the end of this iteration
                        //
                        for (xmlNodePtr node = currentNode->last; node; node = node->prev) {
                            xmlAddNextSibling(currentNode, node);
                        }

                        shouldUnlinkNode = YES;
                    } else if (currentNode->children) {
                        nextNode = currentNode->children;
                    }
                } break;

                case XML_COMMENT_NODE:
                case XML_DTD_NODE: {
                    shouldUnlinkNode = YES;
                } break;

                case XML_TEXT_NODE:
                case XML_CDATA_SECTION_NODE:
                    // Do nothing
                    break;
                default:
                    DDLogWarn(@"unknown node type %d",currentNode->type);
            }

            // If a next node hasn't been set yet, pick the following node.
            if (!nextNode) {
                BOOL stop = NO;

                nextNode = currentNode;
                while (nextNode && !stop) {
                    if (nextNode->next) {
                        // If our current node has a sibling, select it and
                        // halt; we are done.
                        nextNode = nextNode->next;
                        stop = YES;
                    } else {
                        // Looks like we ran out of siblings...
                        // Jump up to the parent node and start iterating
                        // through its siblings.
                        nextNode = nextNode->parent;
                    }
                }
            }

            // Remove the current node if it was marked for removal
            // This should only occur to comment, DTD and element node
            // types (and elements should only be deleted if they are not
            // in the list of permitted names).
            if (shouldUnlinkNode) {
                xmlUnlinkNode(currentNode);
                xmlFreeNode(currentNode);
                currentNode = NULL;
            }

            currentNode = nextNode;
        }

        // Reverse the <html><body><p>...</p></body></html> elements
        // we added on in the beginning. In order to do this, we can just
        // use the same XPath we called earlier, dump each sibling node
        // in the set (no need to iterate back down the tree), and append
        // the results.
        xmlXPathObjectPtr xpathFragmentRoot = xmlXPathEval(xpathExpression, xpathContext);
        if (xpathFragmentRoot) {
            xmlNodeSetPtr nodeSet = xpathFragmentRoot->nodesetval;

            if (!xmlXPathNodeSetIsEmpty(nodeSet)) {
                NSMutableString *sanitizedFragmentString = [[NSMutableString alloc] init];

                for (int idx = 0; idx < xmlXPathNodeSetGetLength(nodeSet); ++idx) {
                    xmlNodePtr node = xmlXPathNodeSetItem(nodeSet, idx);
                    xmlBufferPtr nodeBuffer = xmlBufferCreate();
                    htmlNodeDump(nodeBuffer, document, node);

                    const xmlChar *bufferContents = xmlBufferContent(nodeBuffer);
                    NSInteger bufferLength = xmlBufferLength(nodeBuffer);
                    [sanitizedFragmentString appendString:[[NSString alloc] initWithBytes:bufferContents
                                                                        length:bufferLength
                                                                      encoding:NSUTF8StringEncoding]];
                    xmlBufferFree(nodeBuffer);
                }

                resultString = sanitizedFragmentString;
                xmlResetLastError();
            }

            xmlXPathFreeObject(xpathFragmentRoot);
        }
    }

error:
    if (error) {
        xmlErrorPtr libxmlError = xmlGetLastError();

        if (libxmlError) {
            NSString *errorString = [[NSString alloc] initWithBytes:libxmlError->message
                                                             length:strlen(libxmlError->message)
                                                           encoding:NSUTF8StringEncoding];
            (*error) = [NSError errorWithDomain:MITXMLErrorDomain
                                           code:libxmlError->code
                                       userInfo:@{NSLocalizedDescriptionKey : errorString}];

            xmlResetError(libxmlError);
        }
    }

    // Clean up any messes we made
    if (xpathExpression) free((void*)xpathExpression);
    if (xpathResult) xmlXPathFreeObject(xpathResult);
    if (xpathContext) xmlXPathFreeContext(xpathContext);
    if (document) xmlFreeDoc(document);
    xmlCleanupParser();
    
    return [resultString stringByDecodingXMLEntities];
}

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
    
    NSString *encodedString =  (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef)stringToEncode,
                                                                                  (formUrlEncoded ? CFSTR(" ") : NULL),
                                                                                  (CFStringRef)forceEscapedCharacters,
                                                                                  CFStringConvertNSStringEncodingToEncoding(encoding)));
    
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
    return (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                (CFStringRef)self,
                                                                                                NULL,
                                                                                                CFStringConvertNSStringEncodingToEncoding(encoding)));
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
            DDLogVerbose(@"Replaced %lu of %s -> %s", (unsigned long)entities, entity->entityName, entity->entityCode);
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


- (NSString *)stringByStrippingTags {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>"
                                                                           options:NSRegularExpressionDotMatchesLineSeparators
                                                                             error:&error];
    NSString *stripped = [regex stringByReplacingMatchesInString:self
                                                         options:0
                                                           range:NSMakeRange(0, [self length])
                                                    withTemplate:@" "];
    if (!error) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\s{2,}"
                                                          options:0 error:&error];
        stripped = [regex stringByReplacingMatchesInString:stripped
                                                   options:NSRegularExpressionDotMatchesLineSeparators
                                                     range:NSMakeRange(0, [stripped length])
                                              withTemplate:@" "];
    } else {
        DDLogError(@"%@", error);
        // In case of a problem, return the string as is.
        return self;
    }
    return [stripped stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


@implementation NSDate (MITAdditions)

+ (NSDate *)fakeDateForDining {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    [calendar setTimeZone:[NSTimeZone defaultTimeZone]];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
    components.hour = 20;
    components.year = 2013;
    components.month = 5;
    components.day = 3;
    
    return [calendar dateFromComponents:components];
}

+ (NSDate *) dateForTodayFromTimeString:(NSString *)time
{
    // takes date string of format hh:mm and returns an NSDate with today's date at the specified time.
    
    NSCalendar *cal = [NSCalendar cachedCurrentCalendar];
    NSDateComponents *comp = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSTimeZoneCalendarUnit fromDate:[NSDate date]];
    
    NSArray *timeComponents = [time componentsSeparatedByString:@":"];
    comp.hour = [[timeComponents objectAtIndex:0] integerValue];
    comp.minute = [[timeComponents objectAtIndex:1] integerValue];
    
    return [cal dateFromComponents:comp];
}

#pragma mark Comparing Dates
- (BOOL) isEqualToDateIgnoringTime:(NSDate *)aDate
{
    return [self isEqualToDate:aDate
                    components:(NSYearCalendarUnit |
                                NSMonthCalendarUnit |
                                NSDayCalendarUnit)];
}

- (BOOL)isEqualToTimeIgnoringDay:(NSDate *)date
{
    return [self isEqualToDate:date
                    components:(NSHourCalendarUnit |
                                NSMinuteCalendarUnit)];
}

- (BOOL) isEqualToDate:(NSDate*)otherDate
            components:(NSCalendarUnit)components
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    
    NSDate *date1 = [calendar dateFromComponents:[calendar components:components
                                                             fromDate:self]];
    NSDate *date2 = [calendar dateFromComponents:[calendar components:components
                                                             fromDate:otherDate]];
    
	return [date1 isEqual:date2];
}

- (BOOL) isToday
{
	return [self isEqualToDateIgnoringTime:[NSDate date]];
}

- (BOOL) isTomorrow
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    NSDateComponents *selfComponents = [calendar components:(NSYearCalendarUnit |
                                                             NSMonthCalendarUnit |
                                                             NSDayCalendarUnit)
                                                   fromDate:[self dateBySubtractingDay]];
    
    NSDateComponents *todayComponents = [calendar components:(NSYearCalendarUnit |
                                                              NSMonthCalendarUnit |
                                                              NSDayCalendarUnit)
                                                    fromDate:[NSDate date]];
    
    return [todayComponents isEqual:selfComponents];
}


- (BOOL) isYesterday
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    NSDateComponents *selfComponents = [calendar components:(NSYearCalendarUnit |
                                                             NSMonthCalendarUnit |
                                                             NSDayCalendarUnit)
                                                   fromDate:[self dateByAddingDay]];
    
    NSDateComponents *todayComponents = [calendar components:(NSYearCalendarUnit |
                                                              NSMonthCalendarUnit |
                                                              NSDayCalendarUnit)
                                                    fromDate:[NSDate date]];
    
    return [todayComponents isEqual:selfComponents];
}

- (NSDate *)dateWithoutTime
{
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate *) startOfDay
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    return [calendar dateFromComponents:[calendar components:(NSYearCalendarUnit |
                                                              NSMonthCalendarUnit |
                                                              NSDayCalendarUnit)
                                                    fromDate:self]];
}

- (NSDate *) endOfDay
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    
    NSDate *dayStart = nil;
    NSTimeInterval dayInterval = 0;
    [calendar rangeOfUnit:NSDayCalendarUnit
                startDate:&dayStart
                 interval:&dayInterval
                  forDate:self];
    
    // Subtracting 1 second from the dayInterval since
    // the -endOfDay caller expects an inclusive end date,
    // not an exclusive one
    --dayInterval;
    
    return [dayStart dateByAddingTimeInterval:dayInterval];
}

- (NSDate *)startOfWeek
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *currentDateWeekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
    NSDateComponents *dateComponentsToSubtract = [[NSDateComponents alloc] init];
    dateComponentsToSubtract.day = calendar.firstWeekday - currentDateWeekdayComponents.weekday;
    NSDate *startDate = [calendar dateByAddingComponents:dateComponentsToSubtract toDate:self options:0];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:startDate];
    return [calendar dateFromComponents:components];
}

- (NSDate *) dayBefore
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-1];
    
    // Strip off the time so we return a date that is at the
    // start of the previous day
    NSDateComponents *strippedComponents = [calendar components:(NSYearCalendarUnit |
                                                                     NSMonthCalendarUnit |
                                                                     NSDayCalendarUnit)
                                                           fromDate:self];
    
    return [[NSCalendar cachedCurrentCalendar] dateByAddingComponents:dateComponents
                                                               toDate:[calendar dateFromComponents:strippedComponents]
                                                              options:0];
}

- (NSDate *) dayAfter
{
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:1];
    
    // Strip off the time so we return a date that is at the
    // start of the next day
    NSDateComponents *strippedComponents = [calendar components:(NSYearCalendarUnit |
                                                                     NSMonthCalendarUnit |
                                                                     NSDayCalendarUnit)
                                                           fromDate:self];
    return [calendar dateByAddingComponents:dateComponents
                                     toDate:[calendar dateFromComponents:strippedComponents]
                                    options:0];
}

- (NSDate *)dateByAddingDay
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.day = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dateByAddingWeek
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.week = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dateBySubtractingDay
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.day = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dateBySubtractingWeek
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.week = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dateByAddingYear
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.year = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSArray *)datesInWeek
{
    NSDate *day = [self startOfWeek];
    NSMutableArray *datesInWeek = [[NSMutableArray alloc] initWithArray:@[day]];
    for (int i = 0; i < 6; i++) {
        day = [day dateByAddingDay];
        [datesInWeek addObject:day];
    }
    return [datesInWeek copy];
}

/** Extra compact string representation of the date's time components.
 
 This returns only the time of day for the date. The format is similar to "h:mma", but with the minute component only included when non-zero, e.g. "9pm", "10:30am", "4:01pm".
 
 @return A compact string representation of the date's time components.
 */
- (NSString *) MITShortTimeOfDayString {
    NSDateComponents *components = [[NSCalendar cachedCurrentCalendar] components:NSMinuteCalendarUnit
                                                                         fromDate:self];
    
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
    }    
    
    // If the minute value is not zero, use an alternate format
    // that includes the minutes. Otherwise, just ignore them and
    // only include the hour and period. NSDateFormatter will alter
    // the format strings if the user has either 24h time enabled
    // or has disabled display of the current period.
    if ([components minute]) {
        [formatter setDateFormat:@"h:mma"];
    } else {
        [formatter setDateFormat:@"ha"];
    }
    
    return [formatter stringFromDate:self];
}

- (NSString *)todayTomorrowYesterdayString
{
    static NSDateFormatter *dayOfWeekFormatter;
    if (!dayOfWeekFormatter) {
        dayOfWeekFormatter = [[NSDateFormatter alloc] init];
        [dayOfWeekFormatter setDateFormat:@"EEEE"];
    }
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM d"];
    }
    
    if ([self isToday]) {
        return [NSString stringWithFormat:@"Today, %@", [dateFormatter stringFromDate:self]];
    }
    else if ([self isTomorrow]) {
        return [NSString stringWithFormat:@"Tomorrow, %@", [dateFormatter stringFromDate:self]];
    }
    else if ([self isYesterday]) {
        return [NSString stringWithFormat:@"Yesterday, %@", [dateFormatter stringFromDate:self]];
    }
    else {
        return [NSString stringWithFormat:@"%@, %@", [dayOfWeekFormatter stringFromDate:self], [dateFormatter stringFromDate:self]];
    }
}

- (NSDateComponents *)dayComponents {
    return [[NSCalendar cachedCurrentCalendar] components:(NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
}

- (NSDateComponents *)timeComponents {
    return [[NSCalendar cachedCurrentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:self];
}

/** Returns a date with its time components changed to match the input date.

 @param date The date from which to pull the new time of day.
 @return An NSDate with the receiver's year, month, and day but date's hours, minutes, and seconds.
 */

- (NSDate *)dateWithTimeOfDayFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit |
                                                         NSMonthCalendarUnit |
                                                         NSDayCalendarUnit)
                                               fromDate:self];
    
    NSDateComponents *timeComponents = [calendar components:(NSHourCalendarUnit |
                                                             NSMinuteCalendarUnit |
                                                             NSSecondCalendarUnit)
                                                   fromDate:date];
    
   return [calendar dateByAddingComponents:timeComponents
                                    toDate:[calendar dateFromComponents:components]
                                   options:0];
}



- (BOOL)dateFallsBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    return ([self timeIntervalSince1970] >= [startDate timeIntervalSince1970] &&
            [self timeIntervalSince1970] <= [endDate timeIntervalSince1970]);
}

- (NSString *)ISO8601String
{
	struct tm *timeinfo;
	char buffer[80];
    
	time_t rawtime = (time_t)[self timeIntervalSince1970];
	timeinfo = gmtime(&rawtime);
    
	strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", timeinfo);
    
	return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end

@implementation NSCalendar (MITAdditions)

/** Returns a copy of the current calendar. This method uses CFCalendarCopyCurrent so a
 cached copy may be returned if one is available. Do not assume that multiple calls to this
 method will return the same reference.
 
 @return The logical calendar for the current user.
 @see CFCalendarCopyCurrent
*/
+ (NSCalendar *)cachedCurrentCalendar {
    return (NSCalendar*)CFBridgingRelease(CFCalendarCopyCurrent());
}

@end

@implementation NSIndexPath (MITAdditions)
+ (NSIndexPath*)indexPathWithIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger indexes[indexPath.length];
    [indexPath getIndexes:indexes];

    return [[NSIndexPath alloc] initWithIndexes:indexes length:indexPath.length];
}
@end
