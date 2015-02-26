#import "MITECPAuthnRequestMessage.h"
#import "MITTouchstoneConstants.h"

@implementation MITECPAuthnRequestMessage
@synthesize relayState = _relayState;
@synthesize responseConsumerURL = _responseConsumerURL;

- (instancetype)initWithData:(NSData*)xmlData
{
    self = [super initWithData:xmlData];
    if (self) {

    }

    return self;
}

- (void)dealloc
{
    if (_relayState) { xmlFreeNode(_relayState); }
}

- (xmlNodePtr)relayState
{
    if (!_relayState) {
        xmlXPathContextPtr xpathContext = self.xpathContext;
        if (xpathContext) {
            xmlXPathObjectPtr xpathResult = xmlXPathEval((const xmlChar*)[MITECPRelayStateXPath UTF8String], xpathContext);
            if (xpathResult) {
                BOOL resultIsNodeSet = (xpathResult->type == XPATH_NODESET);
                if (resultIsNodeSet && !xmlXPathNodeSetIsEmpty(xpathResult->nodesetval)) {
                    xmlNodePtr relayStateNode = xmlXPathNodeSetItem(xpathResult->nodesetval, 0);
                    _relayState = xmlCopyNode(relayStateNode, MIT_XML_COPY_RECURSIVE);
                }

                xmlXPathFreeObject(xpathResult);
            }
        }
    }

    return _relayState;
}

- (NSURL*)responseConsumerURL
{
    if (!_responseConsumerURL) {
        xmlXPathContextPtr xpathContext = self.xpathContext;
        if (xpathContext) {
            xmlXPathObjectPtr xpathResult = xmlXPathEval((const xmlChar*)[MITECPResponseConsumerXPath UTF8String], xpathContext);
            if (xpathResult) {
                if (xpathResult->type == XPATH_NODESET) {
                    xmlChar *responseConsumerValue = xmlXPathCastToString(xpathResult);
                    NSString *responseConsumer = [NSString stringWithUTF8String:(const char*)responseConsumerValue];
                    _responseConsumerURL = [NSURL URLWithString:responseConsumer];
                    xmlFree(responseConsumerValue);
                }

                xmlXPathFreeObject(xpathResult);
            }
        }
    }

    return _responseConsumerURL;
}

- (BOOL)hasNextRequest
{
    return (!self.error && self.relayState);
}

- (NSURLRequest*)nextRequestWithURL:(NSURL*)url
{
    xmlDocPtr sourceDocument = self.document;
    xmlDocPtr idpPayload = NULL;

    if (!sourceDocument) {
        return nil;
    }

    idpPayload = xmlCopyDoc(sourceDocument, MIT_XML_COPY_RECURSIVE);
    if (!idpPayload) {
        NSLog(@"failed to copy response document");
        return nil;
    } else {
        xmlXPathObjectPtr xpathResult = NULL;
        xmlXPathContextPtr xpathContext = NULL;

        // Now that we have a copy of the SP's original response, we need to
        // find the SOAP header (if present) and remove it before creating
        // the payload for the IdP
        xpathContext = [MITECPAuthnRequestMessage createXPathContextForDocument:idpPayload];
        if (xpathContext) {
            xpathResult = xmlXPathEval((const xmlChar*)[MITSOAPHeaderXPath UTF8String], xpathContext);
            if (xpathResult) {
                if (xpathResult->type == XPATH_NODESET) {

                    xmlNodeSetPtr nodeSet = xpathResult->nodesetval;
                    if (!xmlXPathNodeSetIsEmpty(nodeSet)) {
                        xmlNodePtr soapHeaderNode = xmlXPathNodeSetItem(nodeSet, 0);
                        xmlXPathNodeSetRemove(nodeSet, 0);

                        xmlUnlinkNode(soapHeaderNode);
                        xmlFreeNode(soapHeaderNode);
                    }
                } else {
                    NSLog(@"expected xpath result of type %d but got %d", XPATH_NODESET, xpathResult->type);
                }
            } else {
                NSLog(@"unable to evaluate XPath, invalid expression '%@'",MITSOAPHeaderXPath);
            }
        } else {
            NSLog(@"failed to create XPath context");
        }


        if (xpathResult) { xmlXPathFreeObject(xpathResult); }
        if (xpathContext) { xmlXPathFreeContext(xpathContext); }
    }


    xmlChar *contentBuffer = NULL;
    int bufferSize = 0;

    xmlDocDumpMemoryEnc(idpPayload, &contentBuffer, &bufferSize, "UTF-8");
    NSData *contentBody = [NSData dataWithBytes:contentBuffer length:bufferSize];
    xmlFree(contentBuffer);

    NSMutableURLRequest *request = [[super nextRequestWithURL:url] mutableCopy];
    request.HTTPBody = contentBody;

    if (idpPayload) { xmlFreeDoc(idpPayload); }
    
    return request;
}

@end
