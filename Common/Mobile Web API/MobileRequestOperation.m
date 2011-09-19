#import <Security/Security.h>

#import "Foundation+MITAdditions.h"
#import "MITConstants.h"
#import "MITJSON.h"
#import "MITLogging.h"
#import "MITMobileServerConfiguration.h"
#import "MobileKeychainServices.h"
#import "MobileRequestAuthenticationTracker.h"
#import "MobileRequestLoginViewController.h"
#import "MobileRequestOperation.h"
#import "SAMLResponse.h"
#import "TouchstoneAuthResponse.h"

static  MobileRequestAuthenticationTracker* gSecureStateTracker = nil;

typedef enum {
    MobileRequestStateOK = 0,
    MobileRequestStateWAYF,
    MobileRequestStateIDP,
    MobileRequestStateAuth,
    MobileRequestStateAuthOK,
    MobileRequestStateCanceled,
    MobileRequestStateAuthError
} MobileRequestState;

@interface MobileRequestOperation ()
@property (nonatomic,copy) NSString *command;
@property (nonatomic,copy) NSString *module;
@property (nonatomic,copy) NSDictionary *parameters;
@property (nonatomic,copy) NSURLRequest *initialRequest;
@property BOOL isExecuting;
@property BOOL isFinished;

@property (nonatomic,copy) NSURLRequest *activeRequest;
@property (retain) NSURLConnection *connection;
@property (nonatomic,retain) MobileRequestLoginViewController *loginViewController;
@property (nonatomic,retain) NSMutableData *requestData;
@property (nonatomic,retain) NSError *requestError;
@property (nonatomic) MobileRequestState requestState;
@property (copy) NSString *touchstoneUser;
@property (copy) NSString *touchstonePassword;


@property (retain) NSRunLoop *operationRunLoop;

// Used to prevent the run loop from prematurely exiting
// if there are no active connections and the class
// is waiting for the user to authenticate
@property (retain) NSTimer *runLoopTimer;


- (BOOL)authenticationRequired;
- (NSURLRequest*)buildURLRequest;
- (void)dispatchCompleteBlockWithResult:(id)jsonResult
                                  error:(NSError*)error;
- (void)displayLoginPrompt;
- (void)finish;
- (void)transitionToState:(MobileRequestState)state
          willSendRequest:(NSURLRequest*)request;

@end

@implementation MobileRequestOperation
@synthesize module = _module,
            command = _command,
            parameters = _parameters,
            usePOST = _usePOST,
            completeBlock = _completeBlock,
            progressBlock = _progressBlock;

@synthesize activeRequest = _activeRequest,
            connection = _connection,
            loginViewController = _loginViewController,
            initialRequest = _initialRequest,
            operationRunLoop = _operationRunLoop,
            runLoopTimer = _runLoopTimer,
            requestData = _requestData,
            requestState = _requestState,
            requestError = _requestError,
            touchstoneUser = _touchstoneUser,
            touchstonePassword = _touchstonePassword;

@dynamic isFinished, isExecuting;

#pragma mark - Class Methods
+ (void)initialize {
    gSecureStateTracker = [[MobileRequestAuthenticationTracker alloc] init];
}

+ (id)operationWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params
{
    MobileRequestOperation *operation = [[self alloc] initWithModule:aModule
                                                             command:theCommand
                                                          parameters:params];
    return [operation autorelease];
}
        
- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params
{
    self = [super init];
    if (self) {
        self.module = aModule;
        self.command = theCommand;
        self.parameters = params;
        self.usePOST = NO;
        
        self.isExecuting = NO;
        self.isFinished = NO;
    }
    
    return self;
}

- (void)dealloc {
    self.module = nil;
    self.command = nil;
    self.parameters = nil;
    self.progressBlock = nil;
    self.completeBlock = nil;
    
    self.activeRequest = nil;
    self.connection = nil;
    self.initialRequest = nil;
    self.operationRunLoop = nil;
    self.requestData = nil;
    self.requestError = nil;
    self.touchstoneUser = nil;
    self.touchstonePassword = nil;
    [super dealloc];
}


#pragma mark - Equality
- (BOOL)isEqual:(NSObject*)object
{
    if ([object isKindOfClass:[self class]]) {
        return [self isEqualToOperation:(MobileRequestOperation*)object];
    } else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToOperation:(MobileRequestOperation*)operation
{
    return ([self.module isEqualToString:operation.module] &&
            [self.command isEqualToString:operation.command] &&
            [self.parameters isEqualToDictionary:operation.parameters]);
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.module hash];
    hash ^= [self.command hash];
    hash ^= [self.parameters hash];
    
    for (NSString *key in self.parameters) {
        hash ^= [key hash];
        hash ^= [[self.parameters objectForKey:key] hash];
    }
    
    return hash;
}

#pragma mark - Lifecycle Methods
- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    NSURLRequest *request = [self urlRequest];
    
    if ([NSURLConnection canHandleRequest:request]) {
        self.initialRequest = request;
        self.requestData = nil;
        self.requestError = nil;
        self.touchstoneUser = nil;
        self.touchstonePassword = nil;
        
        self.isExecuting = YES;
        self.isFinished = NO;
        
        [self retain];
        [self main];
    }
}

- (void)main {
    if ([NSThread isMainThread]) {
        [NSThread detachNewThreadSelector:@selector(main)
                                 toTarget:self
                               withObject:nil];
        return;
    }
    
    self.operationRunLoop = [NSRunLoop currentRunLoop];
    self.runLoopTimer = [[[NSTimer alloc] initWithFireDate:[NSDate distantFuture]
                                                 interval:0.0
                                                   target:self
                                                 selector:nil
                                                 userInfo:nil
                                                  repeats:NO] autorelease];
    [self.operationRunLoop addTimer:self.runLoopTimer
                            forMode:NSDefaultRunLoopMode];
    [self transitionToState:MobileRequestStateOK
            willSendRequest:self.initialRequest];
    
    // Without this (unless we are on the main run loop) the
    // NSURLConnections will never be processed
    [self.operationRunLoop run];
}

- (void)finish {
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    MobileRequestLoginViewController *loginViewController = self.loginViewController;
    self.loginViewController = nil;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (loginViewController) {
            [loginViewController hideActivityView];
            [rootViewController dismissModalViewControllerAnimated:YES];
        }
    });
    
    
    // Wait for the animation to complete and clear the modalViewController
    // property otherwise the backed up blocks might stumble over it
    while ([rootViewController modalViewController] != nil) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    }

    self.activeRequest = nil;
    self.connection = nil;
    self.initialRequest = nil;
    self.operationRunLoop = nil;
    self.requestState = MobileRequestStateOK;
    self.touchstoneUser = nil;
    self.touchstonePassword = nil;
    
    [self.runLoopTimer invalidate];
    self.runLoopTimer = nil;
    
    gSecureStateTracker.authenticationBlock = nil;
    [gSecureStateTracker resumeQueue];
    
    
    // This may not be completely necessary since the operation
    // should be running on it's own thread but there may be
    // cases where the -(void)finish method is called on the main
    // thread (instead of the operation's thread) and it shouldn't
    // block.
    NSData *jsonData = [[self.requestData copy] autorelease];
    NSError *error = [[self.requestError copy] autorelease];
    self.requestData = nil;
    self.requestError = nil;
    dispatch_queue_t parseQueue = dispatch_queue_create("edu.mit.mobile.json-parse", 0);
    dispatch_async(parseQueue, ^(void) {
        id jsonResult = nil;
        NSError *jsonError = error;
        
        if (jsonError == nil) {
            jsonResult = [MITJSON objectWithJSONData:jsonData
                                               error:&jsonError];
        }
        
        [self dispatchCompleteBlockWithResult:((jsonError == nil) ? jsonResult : jsonData)
                                        error:jsonError];
        
        self.isExecuting = NO;
        self.isFinished = YES;
    });
    dispatch_release(parseQueue);
    [self release];
}

- (void)cancel {
    [super cancel];

    self.requestState = MobileRequestStateCanceled;
    
    if (self.connection) {
        [self.connection cancel];
    } else {
        self.requestData = nil;
        self.requestError = [NSError errorWithDomain:NSURLErrorDomain
                                                code:NSUserCancelledError
                                            userInfo:nil];
        [self finish];
    }
}


#pragma mark - Dynamic setters/getters
- (BOOL)isExecuting {
    return _isExecuting;
}

- (void)setIsExecuting:(BOOL)isExecuting {
    if (isExecuting != _isExecuting) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = isExecuting;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isFinished {
    return _isFinished;
}

- (void)setIsFinished:(BOOL)isFinished {
    if (isFinished != _isFinished) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = isFinished;
        [self didChangeValueForKey:@"isFinished"];
    }
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


- (NSURLRequest*)buildURLRequest {
    NSMutableString *urlString = [NSMutableString stringWithString:[MITMobileWebGetCurrentServerURL() absoluteString]];
    
    if ([urlString hasSuffix:@"/"] == NO) {
        [urlString appendString:@"/"];
    }
        
    [urlString appendFormat:@"?module=%@&command=%@",
                            [self.module urlEncodeUsingEncoding:NSUTF8StringEncoding],
                            [self.command urlEncodeUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:[self.parameters count]];
    
    for (NSString *key in self.parameters) {
        NSString *value = [self.parameters objectForKey:key];
        
        if (!([[NSNull null] isEqual:value] || ([value length] == 0))) {
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
    } else {
        if ([paramString length] > 0) {
            [urlString appendFormat:@"&%@",paramString];
        }
        
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:5.0];
        [request setHTTPMethod:@"GET"];
    }
    
    return request; 
}

- (void)dispatchCompleteBlockWithResult:(id)jsonResult error:(NSError*)error {
    if (self.completeBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            self.completeBlock(self,jsonResult,error);
        });
    }
}

- (void)displayLoginPrompt {
    if (self.loginViewController == nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
            MobileRequestLoginViewController *loginView = [[[MobileRequestLoginViewController alloc] initWithUsername:self.touchstoneUser
                                                                                                             password:self.touchstonePassword] autorelease];
            loginView.delegate = self;
            
            [[mainWindow rootViewController] presentModalViewController:loginView
                                                               animated:YES];
            self.loginViewController = loginView;
        });
    }
}

- (void)transitionToState:(MobileRequestState)state
          willSendRequest:(NSURLRequest*)request
{
    self.activeRequest = request;
    self.requestData = nil;
    self.requestState = state;
    self.connection = [[[NSURLConnection alloc] initWithRequest:request
                                                       delegate:self
                                               startImmediately:NO] autorelease];
    [self.connection scheduleInRunLoop:self.operationRunLoop
                               forMode:NSDefaultRunLoopMode];
    [self.connection start];
}


#pragma mark - NSURLConnectionDelegate
#pragma mark -- Authentication/Trust Verification
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    OSStatus error = noErr;
    NSString *serverCAPath = [NSBundle pathForResource:@"server_ca"
                                             ofType:@"der"
                                        inDirectory:[[NSBundle mainBundle] resourcePath]];
    if (serverCAPath == nil) {
        WLog(@"Unable to load server CA");
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    
    NSData *serverCAData = [NSData dataWithContentsOfFile:serverCAPath];
    SecCertificateRef serverCA = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)serverCAData);
    if (serverCA == NULL) {
        ELog(@"Failed to create SecCertificateRef for the server CA");
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        return;
    }
    
    
    NSMutableArray *array = [NSMutableArray array];
    SecTrustRef challengeTrust = [[challenge protectionSpace] serverTrust];
    SecTrustRef serverTrust = NULL;
    for (int i = 0; i < SecTrustGetCertificateCount(challengeTrust); ++i) {
        [array addObject:(id)(SecTrustGetCertificateAtIndex(challengeTrust, i))];
    }
    
    
    SecPolicyRef sslPolicy = SecPolicyCreateSSL(TRUE, (CFStringRef)[[challenge protectionSpace] host]);
    error = SecTrustCreateWithCertificates((CFArrayRef)array,
                                           sslPolicy,
                                           &serverTrust);
    CFRelease(sslPolicy);
    if (error != noErr) {
        ELog(@"Error (%ld): Unable to create SecTrust object",error);
    }
    
    
    NSArray *anchorArray = [NSArray arrayWithObject:(id)serverCA];
    error = SecTrustSetAnchorCertificates(serverTrust, (CFArrayRef)anchorArray);
    if (error != noErr) {
        ELog(@"Error (%ld): Failed to anchor server CA",error);
        goto sec_error;
    }
    
    
    error = SecTrustSetAnchorCertificatesOnly(serverTrust, FALSE);
    if (error != noErr) {
        ELog(@"Error (%ld): Failed to anchor server CA",error);
        goto sec_error;
    }
    
    
    SecTrustResultType trustResult = kSecTrustResultInvalid;
    SecTrustEvaluate(serverTrust, &trustResult);
    if ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified)) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:serverTrust]
             forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }


sec_error:
    CFRelease(serverCA);
    CFRelease(serverTrust);
    
    if (error != noErr) {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}


#pragma mark -- Response Handling
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        BOOL wayfRedirect = [[[request.URL host] lowercaseString] isEqualToString:@"wayf.mit.edu"];
        
        if (wayfRedirect) {
            if (self.requestState == MobileRequestStateOK) {
                self.requestState = MobileRequestStateWAYF;
            } else if (self.requestState == MobileRequestStateAuthOK) {
                // Authentication failed, abort the request
                self.requestState = MobileRequestStateAuthError;
                return nil;
            }
        } else if (self.requestState == MobileRequestStateAuthOK) {
            NSMutableURLRequest *newRequest = [self.initialRequest mutableCopy];
            newRequest.URL = [request URL];
            request = newRequest;
        }
    }
    
    self.activeRequest = request;
    return request;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (self.requestData) {
        [self.requestData setLength:0];
    } else {
        self.requestData = [NSMutableData data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.requestData) {
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
    if (self.progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.progressBlock(bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
        });
    }
}


#pragma mark -- State Dependent methods
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.connection = nil;
    
    switch (self.requestState) {
        case MobileRequestStateWAYF:
        {
            if (self.loginViewController == nil) {
                [gSecureStateTracker suspendQueue];
                if (gSecureStateTracker.authenticationBlock == nil) {
                    [gSecureStateTracker addBlockToQueue:^(BOOL canceled) {
                        if (canceled) {
                            // Authentication is required but the user canceled
                            // the last authentication attempt and the timeout has
                            // not been triggered yet. Abort the request.
                            [self cancel];
                            return;
                        } else {
                            // Authentication is required and this is the first request
                            // to attempt to authenticate. Pop up the login view and
                            // get ready to (attempt) to continue the request once the
                            // queue is resumed
                            [gSecureStateTracker suspendQueue];
                            gSecureStateTracker.authenticationBlock = ^{
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
                                [self transitionToState:MobileRequestStateIDP
                                        willSendRequest:wayfRequest];
                            };
                            [self displayLoginPrompt];
                        }
                    }];
                } else {
                    [gSecureStateTracker addBlockToQueue:^(BOOL canceled) {
                        if (canceled) {
                            // Authentication is required but the user canceled
                            // the last authentication attempt and the timeout has
                            // not been triggered yet. Abort the request.
                            [self cancel];
                            return;
                        } else {
                            // Authentication is required but there is already a login
                            // request ahead of this request. Since access to the credentials
                            // isn't global and they may not be saved (they are discarded
                            // immediately after a authentication attempt) we will need to
                            // re-issue the initial request and hope the cookie works.
                            [self transitionToState:MobileRequestStateOK
                                    willSendRequest:self.initialRequest];
                        }
                    }];
                }
                [gSecureStateTracker resumeQueue];
            }
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
                
                [self transitionToState:MobileRequestStateAuth
                        willSendRequest:wayfRequest];
            }
            break;
        }
        
            
        case MobileRequestStateAuth:
        {
            SAMLResponse *samlResponse = [[[SAMLResponse alloc] initWithResponseData:self.requestData] autorelease];
            if (samlResponse.error) {
                if (samlResponse.error.code == MobileWebInvalidLoginError) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        if (self.loginViewController == nil) {
                            [self displayLoginPrompt];
                        } else {
                            [self.loginViewController hideActivityView];
                            [self.loginViewController showError:@"Please enter a valid username and password"];
                        }
                    });
                    
                    self.touchstonePassword = nil;
                } else {
                    [self connection:connection
                    didFailWithError:samlResponse.error];
                }
            } else {
                self.touchstoneUser = nil;
                self.touchstonePassword = nil;
                NSMutableString *body = [NSMutableString stringWithFormat:@"%@=%@",
                                         [@"SAMLResponse" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                         [samlResponse.samlResponse urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                
                if (samlResponse.relayState) {
                    [body appendFormat:@"&%@=%@",
                     [@"RelayState" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                     [samlResponse.relayState urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                } else {
                    [body appendFormat:@"&%@=%@",
                     [@"TARGET" urlEncodeUsingEncoding:NSUTF8StringEncoding],
                     [samlResponse.target urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                }
                
                
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:samlResponse.postURL];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
                [wayfRequest setValue:@"application/x-www-form-urlencoded"
                   forHTTPHeaderField:@"Content-Type"];
                
                [self transitionToState:MobileRequestStateAuthOK
                        willSendRequest:wayfRequest];
            }
            break;
        }
           
            
        case MobileRequestStateOK:
        case MobileRequestStateAuthOK:
        case MobileRequestStateCanceled:
        case MobileRequestStateAuthError:
        {
            [self finish];
            break;
        }
    }
}
         
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.requestData = nil;
    if (self.requestError == nil) {
        self.requestError = error;
    }
    
    [self finish];
}


#pragma mark - MobileRequestLoginView Delegate Methods
-(void)loginRequest:(MobileRequestLoginViewController *)view didEndWithUsername:(NSString *)username password:(NSString *)password shouldSaveLogin:(BOOL)saveLogin {
    NSString *strippedUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.touchstoneUser = [strippedUsername stringByReplacingOccurrencesOfString:@"@mit.edu"
                                                                      withString:@""
                                                                         options:NSCaseInsensitiveSearch
                                                                           range:NSMakeRange(0, [username length])];
    self.touchstonePassword = password;
    
    if (saveLogin) {
        MobileKeychainSetItem(MobileLoginKeychainIdentifier, username, password);
    } else {
        MobileKeychainDeleteItem(MobileLoginKeychainIdentifier);
    }
    
    [view showActivityView];
    
    dispatch_queue_t authQueue = dispatch_queue_create(NULL, 0);
    dispatch_async(authQueue,gSecureStateTracker.authenticationBlock);
    dispatch_release(authQueue);
}

- (void)cancelWasPressedForLoginRequest:(MobileRequestLoginViewController *)view {
    [gSecureStateTracker userCanceledAuthentication];
    [self cancel];
}
@end
