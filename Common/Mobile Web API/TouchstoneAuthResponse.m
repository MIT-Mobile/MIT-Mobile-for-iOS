#import "TouchstoneAuthResponse.h"
#import "MITConstants.h"
#import "TBXML.h"
#import "TBXML+MIT.h"

@interface TouchstoneAuthResponse ()
@property (nonatomic,retain) NSString* postURLPath;
@property (nonatomic,retain) NSError* error;

- (NSError*)findErrorInDocument:(TBXMLElement*)rootElement;
@end

@implementation TouchstoneAuthResponse
@synthesize postURLPath = _postURLPath;
@synthesize error = _error;

- (id)initWithResponseData:(NSData*)response
{
    self = [super init];
    if (self) {
        TBXML *doc = [[TBXML alloc] initWithXMLData:response];
        
        self.error = [self findErrorInDocument:doc.rootXMLElement];
        
        if (self.error == nil) {
            TBXMLElement *element = [TBXML childElementWithId:@"loginform"
                                                parentElement:doc.rootXMLElement
                                              recursiveSearch:YES];
            if (element) {
                self.postURLPath  = [TBXML valueOfAttributeNamed:@"action"
                                                      forElement:element];
                
                if (self.postURLPath == nil) {
                    self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                                     code:MobileWebUnknownError
                                                 userInfo:nil];
                }
            } else {
                
            }
        }
        
        [doc release];
    }
    
    return self;
}

- (NSError*)findErrorInDocument:(TBXMLElement*)element {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSError *error = nil;
    
    if (element) {
        TBXMLElement *loginboxDiv = [TBXML childElementWithId:@"loginbox"
                                                parentElement:element
                                              recursiveSearch:YES];
        NSArray *array = [TBXML elementsWithPath:[@"div/p" componentsSeparatedByString:@"/"]
                                   parentElement:loginboxDiv];
        
        if ([array count] > 0) {
            NSValue *value = [array objectAtIndex:0];
            TBXMLElement *errorDiv = (TBXMLElement*)[value pointerValue];
            
            if (errorDiv) {
                NSString *elementText = [[TBXML textForElement:errorDiv] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
        }
    } else {
        [userInfo setObject:@"Malformed XML response"
                     forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                    code:MobileWebUnknownError 
                                userInfo:userInfo];
    }
    
    return error;
}

- (void)dealloc {
    self.error = nil;
    self.postURLPath = nil;
    [super dealloc];
}

@end
