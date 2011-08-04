#import "SAMLResponse.h"
#import "MobileWebConstants.h"
#import "TBXML.h"

static NSString * const kShibbolethSAMLKey = @"SAMLResponse";
static NSString * const kShibbolethRelayStateKey = @"RelayState";

@interface SAMLResponse ()
@property (nonatomic,retain) NSURL* postURL;
@property (nonatomic,copy) NSString* samlResponse;
@property (nonatomic,copy) NSString* relayState;
@property (nonatomic,retain) NSError* error;

- (NSError*)findErrorInDocument:(TBXMLElement*)element;
- (NSString*)findSAMLResponseInDocument:(TBXMLElement*)element;
- (NSString*)findRelayStateInDocument:(TBXMLElement*)element;
- (NSURL*)findPostURLInDocument:(TBXMLElement*)element;
- (TBXMLElement*)elementWithNameAttribute:(NSString*)aName inPath:(NSString*)aPath parentElement:(TBXMLElement*)parentElement;
@end


@implementation SAMLResponse
@synthesize postURL,
samlResponse,
relayState,
error;

- (id)initWithResponseData:(NSData*)response
{
    self = [super init];
    if (self) {
        TBXML *doc = [[TBXML alloc] initWithXMLData:response];
        
        if (doc.rootXMLElement) {
            self.error = [self findErrorInDocument:doc.rootXMLElement];
            
            if (self.error == nil) {
                self.samlResponse = [self findSAMLResponseInDocument:doc.rootXMLElement];
                self.relayState = [self findRelayStateInDocument:doc.rootXMLElement];
                self.postURL = [self findPostURLInDocument:doc.rootXMLElement];
            }
        }
        
        [doc release];
    }
    
    return self;
}

- (NSError*)findErrorInDocument:(TBXMLElement*)element {
    TBXMLElement *loginboxDiv = [TBXML childElementWithId:@"loginbox"
                                            parentElement:element
                                          recursiveSearch:YES];
    TBXMLElement *errorDiv = NULL;
    NSArray *array = [TBXML elementsWithPath:[@"div/p" componentsSeparatedByString:@"/"]
                               parentElement:loginboxDiv];
    
    for (NSValue *value in array) {
        TBXMLElement *element = (TBXMLElement*)[value pointerValue];
        NSString *class = [TBXML valueOfAttributeNamed:@"class" forElement:element];
        
        if ([class caseInsensitiveCompare:@"class"] == NSOrderedSame) {
            errorDiv = element;
            break;
        }
    }
    
    if (errorDiv) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[TBXML textForElement:errorDiv]
                     forKey:NSLocalizedDescriptionKey];
        return [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                   code:MobileWebTouchstoneError 
                               userInfo:userInfo];
        
    }
    
    return nil;
}

- (NSString*)findSAMLResponseInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    TBXMLElement *formElement = [self elementWithNameAttribute:kShibbolethSAMLKey
                                                        inPath:@"html/body/form/div/input"
                                                 parentElement:element];
    
    if (formElement) {
        return [TBXML valueOfAttributeNamed:@"value"
                                 forElement:formElement];
    } else {
        self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                         code:MobileWebUnknownError
                                     userInfo:nil];
        return nil;
    }
}

- (NSString*)findRelayStateInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    TBXMLElement *formElement = [self elementWithNameAttribute:kShibbolethRelayStateKey
                                                        inPath:@"html/body/form/div/input"
                                                 parentElement:element];
    
    if (formElement) {
        return [TBXML valueOfAttributeNamed:@"value"
                                 forElement:formElement];
    } else {
        self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                         code:MobileWebUnknownError
                                     userInfo:nil];
        return nil;
    }
}

- (NSURL*)findPostURLInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    NSArray *elements = [TBXML elementsWithPath:[@"html/body/form" componentsSeparatedByString:@"/"]
                                  parentElement:element];
    
    if (elements) {
        TBXMLElement *formElement = (TBXMLElement*)[[elements objectAtIndex:0] pointerValue];
        return [NSURL URLWithString:[TBXML valueOfAttributeNamed:@"action"
                                                      forElement:formElement]];
    } else {
        self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                         code:MobileWebUnknownError
                                     userInfo:nil];
    }
    
    return nil;
}

- (TBXMLElement*)elementWithNameAttribute:(NSString*)aName inPath:(NSString*)aPath parentElement:(TBXMLElement*)parentElement {
    if (parentElement == NULL) {
        return NULL;
    }
    
    NSArray *elements = [TBXML elementsWithPath:[aPath componentsSeparatedByString:@"/"]
                                  parentElement:parentElement];
    
    for (NSValue *value in elements) {
        TBXMLElement *element = (TBXMLElement*)[value pointerValue];
        NSString *name = [TBXML valueOfAttributeNamed:@"name"
                                           forElement:element];
        
        if ([aName caseInsensitiveCompare:name] == NSOrderedSame) {
            return element;
        }
    }
    
    return NULL;
}



- (void)dealloc {
    self.error = nil;
    self.postURL = nil;
    self.samlResponse = nil;
    self.relayState = nil;
    
    [super dealloc];
}
@end
