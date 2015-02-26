#import "MITECPResponseMessage.h"
#import "MITTouchstoneConstants.h"

@implementation MITECPResponseMessage
@synthesize relayState = _relayState;
@synthesize assertionConsumerServiceURL = _assertionConsumerServiceURL;

- (instancetype)initWithData:(NSData *)xmlData
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"use %@",NSStringFromSelector(@selector(initWithData:relayState:))]
                                 userInfo:nil];
}

- (instancetype)initWithData:(NSData*)xmlData relayState:(xmlNodePtr)relayState
{
    self = [super initWithData:xmlData];
    if (self) {
        _relayState = xmlCopyNode(relayState, MIT_XML_COPY_RECURSIVE);
    }

    return self;
}

- (void)dealloc
{
    if (_relayState) { xmlFreeNode(_relayState); }
}

- (NSURL*)assertionConsumerServiceURL
{
    if (!_assertionConsumerServiceURL) {
        xmlXPathContextPtr xpathContext = self.xpathContext;
        if (xpathContext) {
            xmlXPathObjectPtr xpathResult = xmlXPathEval((const xmlChar*)[MITECPAssertionConsumerXPath UTF8String], xpathContext);
            if (xpathResult) {
                if (xpathResult->type == XPATH_NODESET) {
                    xmlChar *assertionConsumerValue = xmlXPathCastToString(xpathResult);
                    NSString *assertionConsumer = [NSString stringWithUTF8String:(const char*)assertionConsumerValue];
                    xmlFree(assertionConsumerValue);

                    _assertionConsumerServiceURL = [NSURL URLWithString:assertionConsumer];
                }

                xmlXPathFreeObject(xpathResult);
            }
        }
    }

    return _assertionConsumerServiceURL;
}

- (NSURLRequest*)nextRequestWithURL:(NSURL*)url
{
    xmlDocPtr sourceDocument = self.document;
    xmlDocPtr spPayload = NULL;

    if (!sourceDocument) {
        return nil;
    }

    spPayload = xmlCopyDoc(sourceDocument, MIT_XML_COPY_RECURSIVE);
    if (!spPayload) {
        NSLog(@"failed to copy response document");
        return nil;
    } else {
        xmlXPathObjectPtr xpathResult = NULL;
        xmlXPathContextPtr xpathContext = NULL;

        // Find the SOAP header, remove all its children and then
        // insert the relay state
        xpathContext = [MITECPResponseMessage createXPathContextForDocument:spPayload];
        if (xpathContext) {
            xpathResult = xmlXPathEval((const xmlChar*)[MITSOAPHeaderXPath UTF8String], xpathContext);
            if (xpathResult) {
                if (xpathResult->type == XPATH_NODESET) {
                    xmlNodeSetPtr nodeSet = xpathResult->nodesetval;
                    if (!xmlXPathNodeSetIsEmpty(nodeSet)) {
                        xmlNodePtr responseRelayState = xmlCopyNode(self.relayState, MIT_XML_COPY_RECURSIVE);
                        xmlNodePtr soapHeaderNode = xmlXPathNodeSetItem(nodeSet, 0);
                        xmlNodePtr childNode = NULL;
                        if (soapHeaderNode != NULL) {
                            childNode = soapHeaderNode->children;
                        }
                        while (childNode != NULL) {
                            xmlNodePtr unlinkedNode = childNode;
                            childNode = unlinkedNode->next;

                            xmlUnlinkNode(unlinkedNode);
                            xmlFreeNode(unlinkedNode);
                        }

                        xmlAddChild(soapHeaderNode, responseRelayState);
                        xmlReconciliateNs(spPayload, soapHeaderNode);
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

    xmlDocDumpMemoryEnc(spPayload, &contentBuffer, &bufferSize, "UTF-8");
    NSData *contentBody = [NSData dataWithBytes:contentBuffer length:bufferSize];
    xmlFree(contentBuffer);

    NSMutableURLRequest *request = [[super nextRequestWithURL:url] mutableCopy];
    request.HTTPBody = contentBody;
    
    if (spPayload) { xmlFreeDoc(spPayload); }
    
    return request;
}

@end
