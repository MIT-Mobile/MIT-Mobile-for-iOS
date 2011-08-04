#import "TouchstoneAuthResponse.h"
#import "MobileWebConstants.h"
#import "TBXML.h"

@interface TouchstoneAuthResponse ()
@property (nonatomic,retain) NSString* postURLPath;
@property (nonatomic,retain) NSError* error;
@end

@implementation TouchstoneAuthResponse
@synthesize postURLPath, error;

- (id)initWithResponseData:(NSData*)response
{
    self = [super init];
    if (self) {
        TBXML *doc = [[TBXML alloc] initWithXMLData:response];
        
        if (doc.rootXMLElement) {
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
                TBXMLElement *loginboxDiv = [TBXML childElementWithId:@"loginbox"
                                                        parentElement:doc.rootXMLElement
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
                    self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                                     code:MobileWebTouchstoneError 
                                                 userInfo:userInfo];
                    
                } else {
                    self.error = [NSError errorWithDomain:MobileWebTouchstoneErrorDomain
                                                     code:MobileWebTouchstoneError
                                                 userInfo:nil];
                }
            }
        } else {
            self.error = [NSError errorWithDomain:MobileWebErrorDomain
                                             code:MobileWebUnknownError
                                         userInfo:nil];
        }
        
        [doc release];
    }
    
    return self;
}

- (void)dealloc {
    self.error = nil;
    self.postURLPath = nil;
    [super dealloc];
}

@end
