#include <libxml/parser.h>
#include <libxml/tree.h>
#import "MITTouchstoneMessage.h"
#import "MITTouchstoneConstants.h"
#import "NSMutableURLRequest+ECP.h"

@interface MITTouchstoneMessage ()

@end

@implementation MITTouchstoneMessage
@synthesize document = _document;
@synthesize xpathContext = _xpathContext;
@dynamic error;

+ (NSDictionary*)defaultNamespaces
{
    return @{@"soap" : MITSOAPNamespaceURI,
             @"ecp" : MITECPNamespaceURI,
             @"paos" : MITPAOSNamespaceURI};
}

+ (xmlXPathContextPtr)createXPathContextForDocument:(xmlDocPtr)document
{
    NSParameterAssert(document);

    xmlXPathContextPtr xpathContext = xmlXPathNewContext(document);
    [[self defaultNamespaces] enumerateKeysAndObjectsUsingBlock:^(NSString *nsPrefix, NSString *nsURI, BOOL *stop) {
        int result = xmlXPathRegisterNs(xpathContext, (const xmlChar*)[nsPrefix UTF8String], (const xmlChar*)[nsURI UTF8String]);
        if (result) {
            NSLog(@"failed to register namespace %@ for prefix %@",nsURI,nsPrefix);
        }
    }];

    return xpathContext;
}

- (instancetype)initWithData:(NSData *)xmlData
{
    NSParameterAssert(xmlData);

    self = [super init];
    if (self) {
        xmlDocPtr document = xmlReadMemory([xmlData bytes], (int)[xmlData length], NULL, NULL, (XML_PARSE_NOWARNING | XML_PARSE_NONET));

        if (!document) {
            NSString *message = @"failed to parse XML document";
            NSLog(@"%@",message);
            self = nil;
        } else {
            _document = document;
        }
    }

    return self;
}

- (void)dealloc
{
    if (_xpathContext) { xmlXPathFreeContext(_xpathContext); }
    if (_document) { xmlFreeDoc(_document); }
}


- (BOOL)hasNextRequest
{
    return NO;
}

- (NSURLRequest*)nextRequestWithURL:(NSURL*)url;
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.];
    request.HTTPMethod = @"POST";
    request.HTTPShouldHandleCookies = YES;
    
    [request setAdvertisesECP];
    [request setValue:MITECPMIMEType forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (xmlXPathContextPtr)xpathContext
{
    if (!_xpathContext) {
        if (!_document) {
            NSLog(@"failed to create xpathContext: no valid XML document exists");
        } else {
            _xpathContext = [MITTouchstoneMessage createXPathContextForDocument:_document];
        }
    }

    return _xpathContext;
}

- (NSError*)error
{
    xmlXPathContextPtr xpathContext = self.xpathContext;
    if (!xpathContext) {
        return nil;
    }

    NSError *result = nil;
    xmlXPathObjectPtr faultXpathResult = xmlXPathEval((const xmlChar*)[MITSOAPFaultXPath UTF8String], xpathContext);
    if (!faultXpathResult) {
        NSLog(@"failed to eval xpath expression: %@",MITSOAPFaultXPath);
    } else {
        xmlXPathObjectType resultType = faultXpathResult->type;
        xmlNodeSetPtr resultNodeSet = faultXpathResult->nodesetval;
        
        if ((XPATH_NODESET == resultType) && !xmlXPathNodeSetIsEmpty(resultNodeSet)) {
            // A 'Fault' node exists and it is an XML element. At this point we should be clear
            // to start pulling out the faultcode and faultmessage elements. If these are not present
            // we should fail spectacularly as they are required per the SOAP spec
            NSString *faultCode = nil;
            xmlXPathObjectPtr xpathResult = xmlXPathEval((const xmlChar*)[MITSOAPFaultStringXPath UTF8String], xpathContext);
            if (xpathResult) {
                BOOL resultIsNodeSet = (xpathResult->type == XPATH_NODESET);
                if (resultIsNodeSet && !xmlXPathNodeSetIsEmpty(xpathResult->nodesetval)) {
                    xmlChar *faultCodeString = xmlXPathCastNodeSetToString(xpathResult->nodesetval);
                    faultCode = [NSString stringWithUTF8String:(const char*)faultCodeString];
                    xmlFree(faultCodeString);
                }

                xmlXPathFreeObject(xpathResult);
                xpathResult = NULL;
            }

            NSString *faultString = nil;
            xpathResult = xmlXPathEval((const xmlChar*)[MITSOAPFaultCodeXPath UTF8String], xpathContext);
            if (xpathResult) {
                BOOL resultIsNodeSet = (xpathResult->type == XPATH_NODESET);
                if (resultIsNodeSet && !xmlXPathNodeSetIsEmpty(xpathResult->nodesetval)) {
                    xmlChar *faultMessageString = xmlXPathCastNodeSetToString(xpathResult->nodesetval);
                    faultString = [NSString stringWithUTF8String:(const char*)faultMessageString];
                    xmlFree(faultMessageString);
                }

                xmlXPathFreeObject(xpathResult);
                xpathResult = NULL;
            }

            NSString *message = [NSString stringWithFormat:@"%@ [%@]",faultString,faultCode];
            NSError *error = [NSError errorWithDomain:MITECPErrorDomain
                                                 code:MITECPErrorFault
                                             userInfo:@{NSLocalizedDescriptionKey : message}];
            result = error;
        }

        xmlXPathFreeObject(faultXpathResult);
    }

    return result;
}

@end