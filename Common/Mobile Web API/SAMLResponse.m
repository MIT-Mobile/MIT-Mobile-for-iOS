#import "SAMLResponse.h"
#import "MITConstants.h"
#import "TBXML.h"
#import "TBXML+MIT.h"
#import "Foundation+MITAdditions.h"

static NSString * const kShibbolethSAMLKey = @"SAMLResponse";
static NSString * const kShibbolethRelayStateKey = @"RelayState";
static NSString * const kShibbolethTargetKey = @"TARGET";

@interface SAMLResponse ()
@property (nonatomic,retain) NSURL* postURL;
@property (nonatomic,copy) NSString* samlResponse;
@property (nonatomic,copy) NSString* relayState;
@property (nonatomic,copy) NSString* target;
@property (nonatomic,retain) NSError* error;

- (NSError*)findErrorInDocument:(TBXMLElement*)element;
- (NSString*)findSAMLResponseInDocument:(TBXMLElement*)element;
- (NSString*)findRelayStateInDocument:(TBXMLElement*)element;
- (NSString*)findTargetInDocument:(TBXMLElement*)element;
- (NSURL*)findPostURLInDocument:(TBXMLElement*)element;
- (TBXMLElement*)elementWithNameAttribute:(NSString*)aName inPath:(NSString*)aPath parentElement:(TBXMLElement*)parentElement;
@end


@implementation SAMLResponse
@synthesize postURL = _postURL,
    samlResponse = _samlResponse,
    relayState = _relayState,
    target = _target,
    error = _error;

- (id)initWithResponseData:(NSData*)response
{
    self = [super init];
    if (self) {
        NSString *xmlDoc = [[[NSString alloc] initWithData:response
                                                  encoding:NSUTF8StringEncoding] autorelease];
        TBXML *doc = [[TBXML alloc] initWithXMLString:[xmlDoc stringByDecodingXMLEntities]];
        
        if (doc.rootXMLElement) {
            self.error = [self findErrorInDocument:doc.rootXMLElement];
            
            if (self.error == nil) {
                self.samlResponse = [self findSAMLResponseInDocument:doc.rootXMLElement];
                self.relayState = [self findRelayStateInDocument:doc.rootXMLElement];
                if (self.relayState == nil) {
                    self.target = [self findTargetInDocument:doc.rootXMLElement];
                }
                
                if ((self.relayState == nil) && (self.target == nil)) {
                    self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                                     code:MobileWebUnknownError
                                                 userInfo:nil];
                }
                
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
    NSArray *array = [TBXML elementsWithPath:[@"div/p" componentsSeparatedByString:@"/"]
                               parentElement:loginboxDiv];
    
    if ([array count] == 0) {
        return nil;
    }
    
    NSValue *value = [array objectAtIndex:0];
    TBXMLElement *errorDiv = (TBXMLElement*)[value pointerValue];
    
    NSError *error = nil;
    if (errorDiv) {
        NSString *elementText = [[TBXML textForElement:errorDiv] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:elementText
                     forKey:NSLocalizedDescriptionKey];
        
        NSRange mitIdpRange = [elementText rangeOfString:@"Please enter a valid username and password"
                                                 options:NSCaseInsensitiveSearch];
        NSRange camsRange = [elementText rangeOfString:@"Enter your email address and password"
                                               options:NSCaseInsensitiveSearch];
        if ((mitIdpRange.location != NSNotFound) || (camsRange.location != NSNotFound)) {
            error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                             code:MobileWebInvalidLoginError
                                         userInfo:userInfo];
        } else {
            error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                        code:MobileWebTouchstoneError 
                                    userInfo:userInfo];
        }
    }
    
    return error;
}

- (NSString*)findSAMLResponseInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    TBXMLElement *formElement = [self elementWithNameAttribute:kShibbolethSAMLKey
                                                        inPath:@"body/form/div/input"
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
                                                        inPath:@"body/form/div/input"
                                                 parentElement:element];
    
    if (formElement) {
        return [TBXML valueOfAttributeNamed:@"value"
                                 forElement:formElement];
    } else {
        return nil;
    }
}

- (NSString*)findTargetInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    TBXMLElement *formElement = [self elementWithNameAttribute:kShibbolethTargetKey
                                                        inPath:@"body/form/div/input"
                                                 parentElement:element];
    
    if (formElement) {
        return [TBXML valueOfAttributeNamed:@"value"
                                 forElement:formElement];
    } else {
        return nil;
    }
}

- (NSURL*)findPostURLInDocument:(TBXMLElement*)element {
    if (self.error) {
        return nil;
    }
    
    NSArray *elements = [TBXML elementsWithPath:[@"body/form" componentsSeparatedByString:@"/"]
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
