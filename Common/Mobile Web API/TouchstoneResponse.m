#import "TouchstoneResponse.h"
#import "GDataHTMLDocument.h"
#import "MITConstants.h"
#import "Foundation+MITAdditions.h"

static NSString * const kShibbolethErrorPath = @"//div[@id='loginbox']/div[@class='error']/p/text()";
static NSString * const kShibbolethLoginFormPath = @"//div[@id='loginbox']/form[@id='loginform']/@action";
static NSString * const kShibbolethLoginUsernamePath = @"//div[@id='loginbox']/form[@id='loginform']/fieldset/label/input[@type='text']/@name";
static NSString * const kShibbolethLoginPasswordPath = @"//div[@id='loginbox']/form[@id='loginform']/fieldset/label/input[@type='password']/@name";

static NSString * const kShibbolethMobileErrorPath = @"//div[@id='container']/div[@class='alertbox warning']/text()";
static NSString * const kShibbolethMobileLoginFormPath = @"//div[@id='container']/form[@id='kform']/@action";
static NSString * const kShibbolethMobileLoginUsernamePath = @"//div[@id='container']/form[@id='kform']//input[@id='username']/@name";
static NSString * const kShibbolethMobileLoginPasswordPath = @"//div[@id='container']/form[@id='kform']//input[@id='pwd']/@name";

static NSString * const kShibbolethAssertActionPath = @"//body/form/@action";
static NSString * const kShibbolethAssertInputsPath = @"//body/form/div/input";

@interface TouchstoneResponse ()
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSData *requestDocument;
@property (nonatomic, retain) NSURL *touchstoneURL;
@property (nonatomic, retain) NSDictionary *touchstoneParameters;
@property (nonatomic) BOOL isSAMLAssertion;

- (void)processResponse;
- (void)processAssertionResponseWithDocument:(GDataXMLDocument*)document;
- (void)processAuthenticationResponseWithDocument:(GDataXMLDocument*)document;
- (NSError*)errorWithDocument:(GDataXMLDocument*)document;
@end

@implementation TouchstoneResponse
@synthesize error = _error;
@synthesize request = _request;
@synthesize requestDocument = _requestDocument;
@synthesize userFieldName = _userFieldName;
@synthesize passwordFieldName = _passwordFieldName;
@synthesize isSAMLAssertion = _isSAMLAssertion;
@synthesize touchstoneURL = _touchstoneURL;
@synthesize touchstoneParameters = _touchstoneParameters;

- (id)initWithRequest:(NSURLRequest*)request data:(NSData*)data
{
    self = [super init];
    
    if (self)
    {
        self.request = request;
        self.requestDocument = data;
        
        [self processResponse];
    }
    
    return self;
}

- (void)processResponse
{
    NSError *parseError = nil;
    GDataXMLDocument *document = [[[GDataHTMLDocument alloc] initWithData:self.requestDocument
                                                                  options:(HTML_PARSE_RECOVER |
                                                                           HTML_PARSE_NOWARNING |
                                                                           HTML_PARSE_NONET)
                                                                    error:&parseError] autorelease];
    
    self.error = (parseError != nil) ? parseError : [self errorWithDocument:document];
    [self processAssertionResponseWithDocument:document];
    [self processAuthenticationResponseWithDocument:document];
}

- (void)processAuthenticationResponseWithDocument:(GDataXMLDocument*)document
{
    if (self.isSAMLAssertion || self.error)
    {
        return;
    }
    
    NSArray *nodes = nil;
    
    NSArray *usernamePaths = [NSArray arrayWithObjects:kShibbolethLoginUsernamePath, kShibbolethMobileLoginUsernamePath, nil];
    GDataXMLNode *usernameNode = nil;
    for (NSString *path in usernamePaths) {
        nodes = [document nodesForXPath:path
                                  error:nil];
        usernameNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
        
        if (usernameNode)
            break;
    }
    nodes = nil;
    
    NSArray *passwordPaths = [NSArray arrayWithObjects:kShibbolethLoginPasswordPath, kShibbolethMobileLoginPasswordPath, nil];
    GDataXMLNode *passwordNode = nil;
    for (NSString *path in passwordPaths) {
        nodes = [document nodesForXPath:path
                                  error:nil];
        passwordNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
        
        if (passwordNode)
            break;
    }
    nodes = nil;
    
    NSArray *actionPaths = [NSArray arrayWithObjects:kShibbolethLoginFormPath, kShibbolethMobileLoginFormPath, nil];
    GDataXMLNode *formNode = nil;
    for (NSString *path in actionPaths) {
        nodes = [document nodesForXPath:path
                                  error:nil];
        formNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
        
        if (formNode)
            break;
    }
    
    if ((usernameNode && passwordNode && formNode) == NO)
    {
        self.error = [NSError errorWithDomain:MobileWebErrorDomain
                                         code:MobileWebTouchstoneError
                                     userInfo:nil];
    }
    else
    {
        self.userFieldName = [usernameNode stringValue];
        self.passwordFieldName = [passwordNode stringValue];
        self.touchstoneURL = [NSURL URLWithString:[formNode stringValue]
                                    relativeToURL:[self.request URL]];
        
        if (self.touchstoneURL == nil)
        {
            self.touchstoneURL = [NSURL URLWithString:[formNode stringValue]];
        }
    }
    
    self.touchstoneParameters = nil;
}

- (void)processAssertionResponseWithDocument:(GDataXMLDocument *)document
{
    if (self.error)
    {
        return;
    }
    
    NSArray *fieldInputs = [document nodesForXPath:kShibbolethAssertInputsPath error:nil];
    NSArray *nodes = [document nodesForXPath:kShibbolethAssertActionPath error:nil];
    GDataXMLNode *formNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
    
    if (formNode)
    {
        self.isSAMLAssertion = YES;
        
        self.touchstoneURL = [NSURL URLWithString:[formNode stringValue]];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        for (GDataXMLNode *node in fieldInputs)
        {
            if ([node kind] == GDataXMLElementKind)
            {
                GDataXMLElement *element = (GDataXMLElement*)node;
                [parameters setObject:[[element attributeForName:@"value"] stringValue]
                               forKey:[[element attributeForName:@"name"] stringValue]];
            }
        }
        
        if ([parameters count])
        {
            self.touchstoneParameters = parameters;
        }
    }
    
}

- (NSError*)errorWithDocument:(GDataXMLDocument*)document
{
    NSError *shibError = nil;

    NSArray *errorPaths = [NSArray arrayWithObjects:kShibbolethErrorPath, kShibbolethMobileErrorPath, nil];

    for (NSString *path in errorPaths) {
        NSArray *nodes = [document nodesForXPath:path
                                           error:nil];
        GDataXMLNode *errorNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : nil;
        
        if (errorNode)
        {
            NSString *errorText = [errorNode stringValue];
            NSInteger errorCode = 0;
            
            if ([errorText containsSubstring:@"password" options:NSCaseInsensitiveSearch])
            {
                errorCode = MobileWebInvalidLoginError;
            }
            else
            {
                errorCode = MobileWebTouchstoneError;
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorText
                                                                 forKey:NSLocalizedDescriptionKey];
            
            shibError = [NSError errorWithDomain:MobileWebErrorDomain
                                            code:errorCode
                                        userInfo:userInfo];
        }
        
        if (shibError) {
            break;
        }
    }
    
    return shibError;
}

@end
