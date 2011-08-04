#import <Security/Security.h>

#import "MITJSON.h"
#import "MobileRequestOperation.h"
#import "TouchstoneAuthResponse.h"
#import "SAMLResponse.h"
#import "MobileKeychainServices.h"
#import "MobileRequestLoginViewController.h"
#import "MobileWebConstants.h"
#import "Foundation+MITAdditions.h"
#import "MITMobileServerConfiguration.h"

static dispatch_queue_t gAuthenticationQueue = NULL;

typedef enum {
    MobileRequestStateOK = 0,
    MobileRequestStateWAYF,
    MobileRequestStateIDP,
    MobileRequestStateAuth,
    MobileRequestStateAuthGET,
    MobileRequestStateCanceled,
    MobileRequestStateAuthError
} MobileRequestState;

@interface MobileRequestOperation ()
@property (nonatomic,copy) NSString *command;
@property (nonatomic,copy) NSString *module;
@property (nonatomic,copy) NSString *pathExtension;
@property (nonatomic,copy) NSDictionary *parameters;
@property (nonatomic,copy) NSURLRequest *initialRequest;
@property (nonatomic,retain) NSMutableData *requestData;
@property (nonatomic) MobileRequestState requestState;
@property (nonatomic,retain) NSError *webError;

@property (copy) NSURLRequest *activeRequest;
@property (retain) NSURLConnection *connection;
@property (copy) NSString *touchstoneUser;
@property (copy) NSString *touchstonePassword;

@property BOOL isExecuting;

- (void)dispatchAuthenticationBlock:(void (^)(void))authBlock;

- (void)dispatchCompleteBlockWithResult:(id)jsonResult error:(NSError*)error;
- (NSURLRequest*)buildURLRequest;
- (void)handleJSONResult:(NSData*)jsonData;

- (BOOL)authenticationRequired;
- (void)displayLoginPrompt;
@end

@implementation MobileRequestOperation
@synthesize module = _module,
            command = _command,
            pathExtension = _pathExtension,
            parameters = _parameters,
            connection = _connection,
            usePOST = _usePOST,
            activeRequest = _activeRequest,
            requestData = _requestData,
            initialRequest,
            requestState,
            webError,
            progressBlock,
            completeBlock,
            touchstoneUser,
            touchstonePassword;

@dynamic isExecuting;

#pragma mark - Class Methods
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (gAuthenticationQueue == NULL) {
            gAuthenticationQueue = dispatch_queue_create("edu.mit.mobile.Authentication", 0);
        }
    });
}

- (void)dispatchAuthenticationBlock:(void (^)(void))authBlock {
    dispatch_async(gAuthenticationQueue, ^(void) {
        dispatch_suspend(gAuthenticationQueue);
        
        if ([self authenticationRequired]) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self displayLoginPrompt];
            });
        } else {
            dispatch_resume(gAuthenticationQueue);
        }
    });
    
    dispatch_async(gAuthenticationQueue, ^(void) {
        if (self.requestState == MobileRequestStateWAYF) {
            dispatch_async(dispatch_get_main_queue(), authBlock);
        }
    });
}


- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params
{
    self = [super init];
    if (self) {
        self.module = aModule;
        self.command = theCommand;
        self.parameters = ((params == nil) ? [NSDictionary dictionary] : params);
        self.pathExtension = nil;
        self.usePOST = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.module = nil;
    self.command = nil;
    self.parameters = nil;
    self.pathExtension = nil;
    self.progressBlock = nil;
    self.completeBlock = nil;
    self.requestData = nil;
    self.activeRequest = nil;
    self.initialRequest = nil;
    [super dealloc];
}

#pragma mark - Overriden Methods
- (void)start {
    NSURLRequest *request = [self urlRequest];
    
    if ([NSURLConnection canHandleRequest:request]) {
        self.activeRequest = request;
        self.initialRequest = request;
        self.isExecuting = YES;
        self.requestData = nil;
        self.requestState = MobileRequestStateOK;
        self.touchstonePassword = nil;
        self.touchstoneUser = nil;
        self.webError = nil;
        
        [self retain];
        self.connection = [[[NSURLConnection alloc] initWithRequest:request
                                                           delegate:self
                                                   startImmediately:NO] autorelease];
        [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                   forMode:NSDefaultRunLoopMode];
        [self.connection start];
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return (self.isExecuting == NO);
}


#pragma mark - Public Methods
- (NSURLRequest*)urlRequest {
    if (self.connection) {
        return self.initialRequest;
    } else {
        return [self buildURLRequest];
    }
}

#pragma mark - Private Methods
- (BOOL)authenticationRequired {
    NSDictionary *authItem = MobileKeychainFindItem(MobileLoginKeychainIdentifier, YES);
    
    if (authItem) {
        self.touchstoneUser = [authItem objectForKey:(id)kSecAttrAccount];
        self.touchstonePassword = [authItem objectForKey:(id)kSecValueData];
    }
    
    BOOL promptForAuth = (authItem == nil);
    promptForAuth = promptForAuth || ([self.touchstoneUser length] == 0);
    promptForAuth = promptForAuth || ([self.touchstonePassword length] == 0);
    
    return promptForAuth;
}

- (void)displayLoginPrompt {
    MobileRequestLoginViewController *loginView = [[MobileRequestLoginViewController alloc] initWithUsername:self.touchstoneUser
                                                                                                    password:self.touchstonePassword];
    loginView.delegate = self;
    
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    [[mainWindow rootViewController] presentModalViewController:loginView
                                                       animated:YES];
    [loginView release];
}

- (void)setIsExecuting:(BOOL)isExecuting {
    @synchronized(self) {
        if (_isExecuting != isExecuting) {
            [self willChangeValueForKey:@"isExecuting"];
            _isExecuting = isExecuting;
            [self didChangeValueForKey:@"isExecuting"];
        }
    }
}

- (void)handleJSONResult:(NSData*)jsonData {
    NSError *jsonError = nil;
    
    id jsonResult = [MITJSON objectWithJSONData:jsonData];
    
    [self dispatchCompleteBlockWithResult:((jsonError == nil) ? jsonResult : jsonData)
                                    error:jsonError];
}

- (void)dispatchCompleteBlockWithResult:(id)jsonResult error:(NSError*)error {
    if (self.completeBlock) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.completeBlock(self,jsonResult,error);
        });
    }
}

- (NSURLRequest*)buildURLRequest {
    NSMutableString *urlString = [NSMutableString stringWithString:[MITMobileWebGetCurrentServerURL() absoluteString]];
    
   if ([urlString hasSuffix:@"/"] == NO) {
        [urlString appendString:@"/"];
    }
    
    if (self.pathExtension) {
        [urlString appendFormat:@"/%@",self.pathExtension];
    }
    
    [urlString appendFormat:@"?module=%@&command=%@",
    [self.module urlEncodeUsingEncoding:NSUTF8StringEncoding],
    [self.command urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:[self.parameters count]];
    
    for (NSString *key in self.parameters) {
        NSString *value = [self.parameters objectForKey:key];
        
        if (!([[NSNull null] isEqual:value] || ([value length] > 0))) {
            NSString *param = [NSString stringWithFormat:@"%@=%@",
                               [key urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES],
                               [value urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
            [params addObject:param];
        }
    }
    
    NSMutableURLRequest *request = nil;
    NSString *paramString = [params componentsJoinedByString:@"&"];
    
    if (self.usePOST) {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:5.0];
        [request setHTTPMethod:@"POST"];
        
        [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setValue:@"application/x-www-form-urlencoded"
       forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%u",[[request HTTPBody] length]]
       forHTTPHeaderField:@"Content-Length"];
    } else {
        if ([paramString length] > 0) {
            [urlString appendFormat:@"&%@",paramString];
        }
        
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:5.0];
        [request setHTTPMethod:@"GET"];
    }
    
    
    [request setHTTPShouldUsePipelining:YES];
    return request; 
}


#pragma mark - NSURLConnectionDelegate
#pragma mark -- Authentication/Trust Verification
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
        return NO;
    }
    
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *mitCAPath = [NSBundle pathForResource:@"mit_ca"
                                             ofType:@"der"
                                        inDirectory:[[NSBundle mainBundle] resourcePath]];
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
        return;
    }
    
    if (mitCAPath == nil) {
        NSLog(@"Error: Unable to load MIT CA");
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }
    
    NSData *mitCAData = [NSData dataWithContentsOfFile:mitCAPath];
    SecCertificateRef mitCA = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)mitCAData);
    
    if (mitCA == NULL) {
        NSLog(@"Error: Failed to create SecCertificateRef for the MIT CA");
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    OSStatus error = noErr;
    SecTrustRef challengeTrust = [[challenge protectionSpace] serverTrust];
    SecTrustRef serverTrust = NULL;
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = 0; i < SecTrustGetCertificateCount(challengeTrust); ++i) {
        [array addObject:(id)(SecTrustGetCertificateAtIndex(challengeTrust, i))];
    }
    
    NSLog(@"Creating trust for host %@", [[challenge protectionSpace] host]);
    
    SecPolicyRef sslPolicy = SecPolicyCreateSSL(TRUE, (CFStringRef)[[challenge protectionSpace] host]);
    error = SecTrustCreateWithCertificates((CFArrayRef)array,
                                           sslPolicy,
                                           &serverTrust);
    CFRelease(sslPolicy);
    
    if (error != noErr) {
        NSLog(@"Error (%ld): Unable to create SecTrust object",error);
        
    }
    
    
    NSArray *anchorArray = [NSArray arrayWithObject:(id)mitCA];
    error = SecTrustSetAnchorCertificates(serverTrust, (CFArrayRef)anchorArray);
    if (error != noErr) {
        NSLog(@"Error (%ld): Failed to anchor MIT CA",error);
        CFRelease(mitCA);
        CFRelease(serverTrust);
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    
    error = SecTrustSetAnchorCertificatesOnly(serverTrust, FALSE);
    if (error != noErr) {
        NSLog(@"Error (%ld): Failed to anchor MIT CA",error);
        CFRelease(mitCA);
        CFRelease(serverTrust);
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    
    SecTrustResultType trustResult = kSecTrustResultInvalid;
    SecTrustEvaluate(serverTrust, &trustResult);
    
    if ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified)) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:serverTrust]
             forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    
    CFRelease(mitCA);
    CFRelease(serverTrust);
}


#pragma mark -- Response Handling
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
        return nil;
    }
    
    if (redirectResponse) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)redirectResponse;
        NSLog(@"Redirecting to %@:%@", [request HTTPMethod], [request URL]);
        
        switch (self.requestState) {
            case MobileRequestStateAuth:
            {
                break;
            }

            case MobileRequestStateAuthGET:
            {
                NSString *locationURL = [request.URL absoluteString];
                
                if ([[locationURL lowercaseString] hasPrefix:@"https://wayf.mit.edu"]) {
                    self.requestState = MobileRequestStateAuthError;
                    return nil;
                }
                break;
            }
                
            case MobileRequestStateOK:
            {
                NSString *locationURL = [[httpResponse allHeaderFields] objectForKey:@"Location"];
                    
                if ([[locationURL lowercaseString] hasPrefix:@"https://wayf.mit.edu"]) {
                    self.requestState = MobileRequestStateWAYF;
                }
                break;
            }
                
            default:
                break;
        }
    
        NSMutableURLRequest *newRequest = [[request mutableCopy] autorelease];
        [newRequest setHTTPMethod:@"GET"];
        //[newRequest setURL:[NSURL URLWithString:[[httpResponse allHeaderFields] objectForKey:@"Location"]]];
        //[newRequest setURL:[request URL]];
            
        self.activeRequest = newRequest;
        return newRequest;
    } else {
        return request;
    }
    
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
    } else if (self.requestData) {
        [self.requestData setLength:0];
    } else {
        self.requestData = [NSMutableData data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
    } else if (self.requestData) {
        [self.requestData appendData:data];
    } else {
        self.requestData = [NSMutableData data];
    }
    
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
    } else if (self.progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.progressBlock(bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
        });
    }
}


#pragma mark -- State Dependent methods
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.isCancelled) {
        self.requestState = MobileRequestStateCanceled;
        [connection cancel];
        return;
    }
    
    switch (self.requestState) {
        case MobileRequestStateAuthGET:
        case MobileRequestStateOK:
        {
            if (self.requestData) {
                NSData *blockData = [NSData dataWithData:self.requestData];
                
                dispatch_queue_t parseQueue = dispatch_queue_create("edu.mit.mobile.json-parse", 0);
                dispatch_async(parseQueue, ^(void) {
                    [self handleJSONResult:blockData];
                    self.isExecuting = NO;
                    [self release];
                });
                dispatch_release(parseQueue);
            } else {
                [self dispatchCompleteBlockWithResult:nil
                                                error:nil];
                self.isExecuting = NO;
                [self release];
            }
            
            self.activeRequest = nil;
            self.connection = nil;
            self.requestData = nil;
            break;
        }
            
        case MobileRequestStateWAYF:
        {
            [self dispatchAuthenticationBlock:^(void) {
                
                NSLog(@"Logging in as %@", [self touchstoneUser]);
                NSString *idp = nil;
                
                NSRange range = [self.touchstoneUser rangeOfString:@"@"];
                BOOL useMitIdp = [self.touchstoneUser hasSuffix:@"@mit.edu"];
                useMitIdp = useMitIdp || (range.location == NSNotFound);
                
                if (useMitIdp) {
                    idp = @"https://idp.mit.edu/shibboleth";
                } else {
                    idp = @"https://idp.touchstonenetwork.net/shibboleth-idp";
                }
                
                NSString *body = [NSString stringWithFormat:@"user_idp=%@",[idp urlEncodeUsingEncoding:NSUTF8StringEncoding
                                                                                     useFormURLEncoded:YES]];
                
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:[self.activeRequest URL]];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
                
                self.requestState = MobileRequestStateIDP;
                self.requestData = nil;
                self.activeRequest = wayfRequest;
                self.connection = [[[NSURLConnection alloc] initWithRequest:wayfRequest
                                                                   delegate:self
                                                           startImmediately:YES] autorelease];
            }];
            break;
        }
        
        case MobileRequestStateIDP:
        {
            TouchstoneAuthResponse *tsResponse = [[[TouchstoneAuthResponse alloc] initWithResponseData:self.requestData] autorelease];
            
            if (tsResponse.error) {
                [self connection:connection
                didFailWithError:tsResponse.error];
            } else {
                NSString *body = [NSString stringWithFormat:@"%@=%@&%@=%@",
                                  [@"j_username" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [self.touchstoneUser urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES],
                                  [@"j_password" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [self.touchstonePassword urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                                  
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:tsResponse.postURLPath
                                                                                              relativeToURL:[self.activeRequest URL]]];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                [wayfRequest setValue:@"application/x-www-form-urlencoded"
                   forHTTPHeaderField:@"Content-Type"];
                
                self.requestState = MobileRequestStateAuth;
                self.requestData = nil;
                self.activeRequest = wayfRequest;
                self.connection = [[[NSURLConnection alloc] initWithRequest:wayfRequest
                                                                   delegate:self
                                                           startImmediately:YES] autorelease];
            }
            break;
        }
            
        case MobileRequestStateAuth:
        {
            SAMLResponse *samlResponse = [[[SAMLResponse alloc] initWithResponseData:self.requestData] autorelease];
            
            if (samlResponse.error) {
                [self connection:connection
                didFailWithError:samlResponse.error];
            } else {
                NSString *body = [NSString stringWithFormat:@"%@=%@&%@=%@",
                                  [@"SAMLResponse" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [samlResponse.samlResponse urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES],
                                  [@"RelayState" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [samlResponse.relayState urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                
                
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:samlResponse.postURL];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
                
                self.requestState = MobileRequestStateAuthGET;
                self.requestData = nil;
                self.activeRequest = wayfRequest;
                self.connection = [[[NSURLConnection alloc] initWithRequest:wayfRequest
                                                                   delegate:self
                                                           startImmediately:YES] autorelease];
            }
            break;
        }
        
        case MobileRequestStateCanceled:
        case MobileRequestStateAuthError:
        {
            [self dispatchCompleteBlockWithResult:nil
                                            error:self.webError];
            self.activeRequest = nil;
            self.connection = nil;
            self.requestData = nil;
            break;
        }
    }
}
         
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed: %@", error);
    [self dispatchCompleteBlockWithResult:nil
                                    error:error];
    
    self.activeRequest = nil;
    self.requestData = nil;
    self.connection = nil;
    self.isExecuting = NO;
    [self release];
}


#pragma mark - MobileRequestLoginView Delegate Methods
-(void)loginRequest:(MobileRequestLoginViewController *)view didEndWithUsername:(NSString *)username password:(NSString *)password shouldSaveLogin:(BOOL)saveLogin {
    if (saveLogin) {
        MobileKeychainSetItem(MobileLoginKeychainIdentifier, username, password);
    } else {
        MobileKeychainDeleteItem(MobileLoginKeychainIdentifier);
    }
    
    self.touchstoneUser = username;
    self.touchstonePassword = password;
    
    
    dispatch_resume(gAuthenticationQueue);
    [view dismissModalViewControllerAnimated:YES];
}

- (void)cancelWasPressesForLoginRequest:(MobileRequestLoginViewController *)view {
    self.requestState = MobileRequestStateCanceled;
    self.webError = [NSError errorWithDomain:MobileWebErrorDomain
                                        code:MobileWebUserCanceled
                                    userInfo:nil];
    dispatch_resume(gAuthenticationQueue);
    [view dismissModalViewControllerAnimated:YES];
}
@end
