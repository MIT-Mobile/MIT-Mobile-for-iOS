#import "Foundation+MITAdditions.h"
#import "MITJSON.h"
#import "MITMobileServerConfiguration.h"
#import "MobileKeychainServices.h"
#import "MobileRequestAuthenticationTracker.h"
#import "MobileRequestLoginViewController.h"
#import "MobileRequestOperation.h"
#import "TouchstoneResponse.h"
#import "MIT_MobileAppDelegate.h"


static MobileRequestAuthenticationTracker *gSecureStateTracker = nil;

typedef enum
{
    MobileRequestStateOK = 0,
    MobileRequestStateWAYF,
    MobileRequestStateIDP,
    MobileRequestStateAuthOK,
    MobileRequestStateCanceled,
    MobileRequestStateAuthError
} MobileRequestState;

@interface MobileRequestOperation ()
@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong) NSString *module;
@property (nonatomic, copy) NSDictionary *parameters;

@property (nonatomic, strong) NSURL *requestBaseURL;
@property (nonatomic, copy) NSURLRequest *initialRequest;

@property (nonatomic) BOOL presetCredentials;
@property BOOL isExecuting;
@property BOOL isFinished;

@property (nonatomic, copy) NSURLRequest *activeRequest;
@property (retain) NSURLConnection *connection;
@property (nonatomic, strong) MobileRequestLoginViewController *loginViewController;
@property (nonatomic, strong) NSMutableData *contentData;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSError *requestError;
@property (nonatomic) MobileRequestState requestState;
@property (copy) NSString *touchstoneUser;
@property (copy) NSString *touchstonePassword;


@property (nonatomic, strong) NSRunLoop *operationRunLoop;

// Used to prevent the run loop from prematurely exiting
// if there are no active connections and the class
// is waiting for the user to authenticate
@property (nonatomic, strong) NSTimer *runLoopTimer;

+ (NSString *)descriptionForState:(MobileRequestState)state;

- (BOOL)authenticationRequired;
- (NSURLRequest*)buildURLRequest;
- (void)dispatchCompleteBlockWithResult:(id)content
                            contentType:(NSString*)contentType
                                  error:(NSError*)error;
- (void)displayLoginPrompt;

- (void)displayLoginPrompt:(BOOL)forceDisplay;

- (void)finish;
- (void)transitionToState:(MobileRequestState)state
          willSendRequest:(NSURLRequest*)request;

@end

@implementation MobileRequestOperation
{
    BOOL _isExecuting;
    BOOL _isFinished;
}

@synthesize requestBaseURL = _requestBaseURL;
@synthesize module = _module;
@synthesize command = _command;
@synthesize parameters = _parameters;
@synthesize usePOST = _usePOST;
@synthesize presetCredentials = _presetCredentials;
@synthesize completeBlock = _completeBlock;
@synthesize progressBlock = _progressBlock;

@synthesize activeRequest = _activeRequest;
@synthesize connection = _connection;
@synthesize loginViewController = _loginViewController;
@synthesize initialRequest = _initialRequest;
@synthesize operationRunLoop = _operationRunLoop;
@synthesize runLoopTimer = _runLoopTimer;
@synthesize contentData = _requestData;
@synthesize contentType = _requestType;
@synthesize requestState = _requestState;
@synthesize requestError = _requestError;
@synthesize touchstoneUser = _touchstoneUser;
@synthesize touchstonePassword = _touchstonePassword;

@dynamic isFinished, isExecuting;

#pragma mark - Class Methods
+ (void)initialize
{
    gSecureStateTracker = [[MobileRequestAuthenticationTracker alloc] init];
}


+ (id)operationWithURL:(NSURL *)requestURL parameters:(NSDictionary *)params
{
    return [[self alloc] initWithURL:requestURL
                          parameters:params];
}

+ (id)operationWithRelativePath:(NSString *)relativePath parameters:(NSDictionary *)params
{
    return [[self alloc] initWithRelativePath:relativePath
                                   parameters:params];
}

+ (id)operationWithModule:(NSString *)aModule command:(NSString *)theCommand parameters:(NSDictionary *)params
{
    return [[self alloc] initWithModule:aModule
                                command:theCommand
                             parameters:params];
}


+ (NSString *)descriptionForState:(MobileRequestState)state
{
    switch (state)
    {
        case MobileRequestStateOK:
            return @"MobileRequestStateOK";
            
        case MobileRequestStateWAYF:
            return @"MobileRequestStateWAYF";
            
        case MobileRequestStateIDP:
            return @"MobileRequestStateIDP";
            
        case MobileRequestStateAuthOK:
            return @"MobileRequestStateAuthOK";
            
        case MobileRequestStateCanceled:
            return @"MobileRequestStateCanceled";
            
        case MobileRequestStateAuthError:
            return @"MobileRequestStateAuthError";
            
        default:
            return @"MobileRequestStateUnknown";
    }
}

+ (BOOL)isAuthenticationCookie:(NSHTTPCookie *)cookie
{
    NSString *name = [cookie name];
    return ([name containsSubstring:@"_shib" options:NSCaseInsensitiveSearch] ||
            [name containsSubstring:@"_idp" options:NSCaseInsensitiveSearch] ||
            [name containsSubstring:@"JSESSION" options:NSCaseInsensitiveSearch] ||
            [name containsSubstring:@"_device" options:NSCaseInsensitiveSearch]);
}

+ (void)clearAuthenticatedSession
{
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStore cookies])
    {
        DLog(@"Checking '%@'", [cookie name]);
        BOOL samlCookie = [[cookie name] containsSubstring:@"_saml"
                                                   options:NSCaseInsensitiveSearch];
        
        if (samlCookie || [self isAuthenticationCookie:cookie])
        {
            DLog(@"Deleting cookie: %@[%@]", [cookie name], [cookie domain]);
            [cookieStore deleteCookie:cookie];
        }
    }
}

+ (NSString *)userAgent
{
    NSMutableArray *userAgent = [NSMutableArray array];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    if (appName == nil)
    {
        appName = [infoDictionary objectForKey:@"CFBundleName"];
    }
    
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    if (appVersion == nil)
    {
        appVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    }
    appVersion = [[appVersion componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    
    NSString *appRevision = [infoDictionary objectForKey:@"MITBuildDescription"];
    if (appRevision == nil)
    {
        appRevision = @"";
    }
    
    [userAgent addObject:[NSString stringWithFormat:@"%@/%@ (%@;)",
                          appName,
                          appVersion,
                          appRevision]];
    
    
    NSMutableString *deviceInfo = [NSMutableString string];
    UIDevice *device = [UIDevice currentDevice];
    
    NSString *osName = [[[device systemName] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    [deviceInfo appendFormat:@"%@/%@ (", osName, [device systemVersion]];
    [deviceInfo appendFormat:@"%@; ", [device model]];
    [deviceInfo appendFormat:@"%@; ", [device cpuType]];
    [deviceInfo appendFormat:@"%@;", [device sysInfoByName:@"hw.machine"]];
    [deviceInfo appendFormat:@")"];
    [userAgent addObject:deviceInfo];
    
    return [userAgent componentsJoinedByString:@" "];
}


#pragma mark - Instance Methods
- (id)initWithModule:(NSString *)aModule command:(NSString *)theCommand parameters:(NSDictionary *)params
{
    NSURL *baseURL = MITMobileWebGetCurrentServerURL();
    
    if ([aModule length] || [theCommand length])
    {
        NSMutableArray *coreParams = [NSMutableArray array];
        
        if ([aModule length])
        {
            [coreParams addObject:[NSString stringWithFormat:@"module=%@",[aModule urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        }
        
        if ([theCommand length])
        {
            [coreParams addObject:[NSString stringWithFormat:@"command=%@",[theCommand urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        }
        
        NSString *urlString = [NSString stringWithFormat:@"%@?%@", [baseURL absoluteString], [coreParams componentsJoinedByString:@"&"]];
        baseURL = [NSURL URLWithString:urlString];
        DLog(@"Initialized module request with URL '%@'", urlString);
    }
    
    id objSelf = [self initWithURL:baseURL
                        parameters:params];
    
    if (objSelf)
    {
        self.module = aModule;
        self.command = theCommand;
    }
    
    return objSelf;
}

- (id)initWithRelativePath:(NSString *)relativePath parameters:(NSDictionary *)params
{
    return [self initWithURL:[NSURL URLWithString:relativePath
                                    relativeToURL:MITMobileWebGetCurrentServerURL()]
                  parameters:params];
}

- (id)initWithURL:(NSURL *)requestURL parameters:(NSDictionary *)params
{
    self = [super init];
    
    if (self)
    {
        self.module = nil;
        self.command = nil;
        self.requestBaseURL = requestURL;
        self.parameters = params;
        self.usePOST = NO;
        
        self.isExecuting = NO;
        self.isFinished = NO;
        self.presetCredentials = NO;
    }
    
    return self;
}

- (void)dealloc
{
    self.requestBaseURL = nil;
    self.module = nil;
    self.command = nil;
    self.parameters = nil;
    self.progressBlock = nil;
    self.completeBlock = nil;
    
    self.activeRequest = nil;
    self.connection = nil;
    self.initialRequest = nil;
    self.operationRunLoop = nil;
    self.contentData = nil;
    self.requestError = nil;
    self.touchstoneUser = nil;
    self.touchstonePassword = nil;
    
    [self.runLoopTimer invalidate];
    self.runLoopTimer = nil;
}


#pragma mark - Equality
- (BOOL)isEqual:(NSObject *)object
{
    if ([object isKindOfClass:[self class]])
    {
        return [self isEqualToOperation:(MobileRequestOperation *) object];
    }
    else
    {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToOperation:(MobileRequestOperation *)operation
{
    return ([self.requestBaseURL isEqual:operation.requestBaseURL] &&
            [self.parameters isEqualToDictionary:operation.parameters]);
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.module hash];
    hash ^= [self.command hash];
    hash ^= [self.parameters hash];
    
    for (NSString *key in self.parameters)
    {
        hash ^= [key hash];
        hash ^= [[self.parameters objectForKey:key] hash];
    }
    
    return hash;
}

#pragma mark - Lifecycle Methods
- (BOOL)isConcurrent
{
    return YES;
}

- (void)start
{
    NSURLRequest *request = [self urlRequest];
    
    if ([NSURLConnection canHandleRequest:request])
    {
        self.initialRequest = request;
        self.contentData = nil;
        self.requestError = nil;
        
        self.isExecuting = YES;
        self.isFinished = NO;
        
        [self main];
    }
}

- (void)main
{
    if ([NSThread isMainThread])
    {
        [NSThread detachNewThreadSelector:@selector(main)
                                 toTarget:self
                               withObject:nil];
        return;
    }
    
    @autoreleasepool {
        self.operationRunLoop = [NSRunLoop currentRunLoop];
        self.runLoopTimer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture]
                                                     interval:0.0
                                                       target:self
                                                     selector:nil userInfo:nil repeats:NO];
        [self.operationRunLoop addTimer:self.runLoopTimer
                                forMode:NSDefaultRunLoopMode];
        [self transitionToState:MobileRequestStateOK
                willSendRequest:self.initialRequest];
        
        // Without this (unless we are on the main run loop) the
        // NSURLConnections will never be processed
        [self.operationRunLoop run];
    }
}

- (void)finish
{
    self.loginViewController = nil;
    self.activeRequest = nil;
    self.connection = nil;
    self.initialRequest = nil;
    self.operationRunLoop = nil;
    self.requestState = MobileRequestStateOK;
    self.touchstoneUser = nil;
    self.touchstonePassword = nil;
    
    [self.runLoopTimer invalidate];
    self.runLoopTimer = nil;
    [gSecureStateTracker resumeQueue];
    
    
    // Grab the pointers to the data we'll need
    // otherwise, since the properties are method calls
    // not direct ivar accesses, will be a potential race
    // condition between the block running and the
    // ivar being deallocated
    NSData *content = self.contentData;
    NSString *contentType = self.contentType;
    NSError *error = self.requestError;
    
    self.contentData = nil;
    self.contentType = nil;
    self.requestError = nil;
    dispatch_queue_t parseQueue = dispatch_queue_create("edu.mit.mobile.json-parse", 0);
    dispatch_async(parseQueue, ^(void) {
        
        BOOL chkJSON = NO;
        NSData *chkData = [content subdataWithRange:NSMakeRange(0, MIN(32,[content length]))];
        NSString *chkString = [[NSString alloc] initWithData:chkData
                                                    encoding:NSUTF8StringEncoding];
        chkString = [chkString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
#warning Remove the chk* variables once the server properly reports the Content-Type for JSON data
        chkJSON = ((chkString != nil) &&
                   (([chkString length] == 0) ||
                    ([chkString hasPrefix:@"["]) ||
                    ([chkString hasPrefix:@"{"])));
        
        if (chkJSON || [contentType containsSubstring:@"json" options:NSCaseInsensitiveSearch])
        {
            id jsonResult = nil;
            NSError *jsonError = error;
            
            if (jsonError == nil) {
                jsonResult = [MITJSON objectWithJSONData:content
                                                   error:&jsonError];
            }
            
            [self dispatchCompleteBlockWithResult:jsonResult
                                      contentType:@"application/json"
                                            error:jsonError];
        }
        else
        {
            [self dispatchCompleteBlockWithResult:content
                                      contentType:contentType
                                            error:error];
        }
        
        self.isExecuting = NO;
        self.isFinished = YES;
    });
    
    dispatch_release(parseQueue);
}

- (void)cancel
{
    [super cancel];
    
    if (self.isExecuting)
    {
        self.requestState = MobileRequestStateCanceled;
        
        if (self.connection)
        {
            [self.connection cancel];
        } else {
            self.contentData = nil;
            
            if (self.requestError == nil)
            {
                self.requestError = [NSError errorWithDomain:MobileWebErrorDomain
                                                        code:NSUserCancelledError
                                                    userInfo:nil];
            }
            [self finish];
        }
    }
}


#pragma mark - Dynamic setters/getters
- (BOOL)isExecuting
{
    return _isExecuting;
}

- (void)setIsExecuting:(BOOL)isExecuting
{
    if (isExecuting != _isExecuting)
    {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = isExecuting;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (void)setIsFinished:(BOOL)isFinished
{
    if (isFinished != _isFinished)
    {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = isFinished;
        [self didChangeValueForKey:@"isFinished"];
    }
}


#pragma mark - Public Methods
- (NSURLRequest *)urlRequest
{
    if (self.connection)
    {
        return self.initialRequest;
    }
    else
    {
        return [self buildURLRequest];
    }
}


- (void)authenticateUsingUsername:(NSString *)username password:(NSString *)password
{
    if ([username length] && [password length])
    {
        self.presetCredentials = YES;
        self.touchstoneUser = username;
        self.touchstonePassword = password;
    }
    else
    {
        self.presetCredentials = NO;
        self.touchstoneUser = nil;
        self.touchstonePassword = nil;
    }
}


#pragma mark - Private Methods
- (BOOL)authenticationRequired
{
    NSDictionary *authItem = nil;
    if (self.presetCredentials == NO)
    {
        authItem = MobileKeychainFindItem(MobileLoginKeychainIdentifier, YES);
        
        if (authItem)
        {
            self.touchstoneUser = [authItem objectForKey:(__bridge id)kSecAttrAccount];
            self.touchstonePassword = [authItem objectForKey:(__bridge id)kSecValueData];
        }
    }
    
    BOOL promptForAuth = (authItem == nil);
    promptForAuth = promptForAuth || ([self.touchstoneUser length] == 0);
    promptForAuth = promptForAuth || ([self.touchstonePassword length] == 0);
    
    if (self.presetCredentials)
    {
        return NO;
    }
    else
    {
        return promptForAuth;
    }
}


- (NSURLRequest *)buildURLRequest
{
    NSMutableString *urlString = [NSMutableString stringWithString:[self.requestBaseURL absoluteString]];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:[self.parameters count]];
    
    for (NSString *key in self.parameters)
    {
        NSString *value = [self.parameters objectForKey:key];
        
        if (!([[NSNull null] isEqual:value] || ([value length] == 0)))
        {
            NSString *param = [NSString stringWithFormat:@"%@=%@",
                               [key urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES],
                               [value urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
            [params addObject:param];
        }
    }
    
    NSMutableURLRequest *request = nil;
    NSString *paramString = [params componentsJoinedByString:@"&"];
    
    if (self.usePOST)
    {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:5.0];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:@"application/x-www-form-urlencoded"
       forHTTPHeaderField:@"Content-Type"];
    }
    else
    {
        if ([paramString length] > 0)
        {
            
            // Assume that the URL is properly formed. In that case,
            // the parameters should come after the '?' and there shouldn't
            // be any stray '?' characters as they are reserved
            if ([urlString containsSubstring:@"?" options:0])
            {
                if ([urlString hasSuffix:@"?"])
                {
                    // Assume the URL is of the format '.../someResource/?...' or '.../someResource?...'
                    [urlString appendFormat:@"%@", paramString];
                }
                else
                {
                    // Assume the url is of the format '...?(parameters*)'
                    [urlString appendFormat:@"&%@", paramString];
                }
            }
            else
            {
                // Assume the URL is of the format '.../someResource/' or '.../someResource'
                [urlString appendFormat:@"?%@", paramString];
            }
        }
        
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:5.0];
        [request setHTTPMethod:@"GET"];
    }
    
    return request;
}

- (void)dispatchCompleteBlockWithResult:(id)content
                            contentType:(NSString*)contentType
                                  error:(NSError*)error {
    if (self.completeBlock) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            self.completeBlock(self,content,contentType,error);
        });
    }
}

- (void)displayLoginPrompt
{
    [self displayLoginPrompt:NO];
}

- (void)displayLoginPrompt:(BOOL)forceDisplay
{
    if (self.loginViewController == nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self authenticationRequired] || forceDisplay)
            {
                MobileRequestLoginViewController *loginView = [[MobileRequestLoginViewController alloc] initWithUsername:self.touchstoneUser
                                                                                                                password:self.touchstonePassword];
                loginView.delegate = self;
                
                UINavigationController *loginNavController = [[UINavigationController alloc] initWithRootViewController:loginView];
                loginNavController.navigationBar.barStyle = UIBarStyleBlack;
                
                [[MITAppDelegate() rootNavigationController] presentModalViewController:loginNavController
                                                                               animated:YES];
                self.loginViewController = loginView;
            }
            else
            {
                [gSecureStateTracker dispatchAuthenticationBlock];
            }
        });
    }
}

- (void)transitionToState:(MobileRequestState)state
          willSendRequest:(NSURLRequest *)request
{
    
    MobileRequestState prevState = self.requestState;
    self.requestState = state;
    
    if (request)
    {
        if (request.URL == nil)
        {
            NSMutableString *errorString = [NSMutableString string];
            [errorString appendString:@"Unable to send request: nil URL requested"];
            [errorString appendFormat:@"\n\tTransition: [%@]->[%@]",
             [MobileRequestOperation descriptionForState:prevState],
             [MobileRequestOperation descriptionForState:state]];
            [errorString appendFormat:@"\n\tURL: %@", self.activeRequest.URL];
            ELog(@"%@", errorString);
        }
        
        DLog(@"Transition:\n\t'%@' -> '%@'",
             [MobileRequestOperation descriptionForState:prevState],
             [MobileRequestOperation descriptionForState:state]);
        DLog(@"\tFor URL:\n\t\t:%@", request.URL);
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.timeoutInterval = 10.0;
        [mutableRequest addValue:[MobileRequestOperation userAgent]
              forHTTPHeaderField:@"User-Agent"];
        
        self.activeRequest = mutableRequest;
        self.contentData = nil;
        self.connection = [[NSURLConnection alloc] initWithRequest:mutableRequest
                                                          delegate:self
                                                  startImmediately:NO];
        [self.connection scheduleInRunLoop:self.operationRunLoop
                                   forMode:NSDefaultRunLoopMode];
        [self.connection start];
    }
}

#pragma mark - NSURLConnectionDelegate
#pragma mark -- Response Handling
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse)
    {
        DLog(@"Redirecting to '%@'", request.URL);
        
        BOOL wayfRedirect = [[[request.URL host] lowercaseString] isEqualToString:@"wayf.mit.edu"];
        
        if (wayfRedirect)
        {
            if (self.requestState == MobileRequestStateOK)
            {
                self.requestState = MobileRequestStateWAYF;
            }
            else if (self.requestState == MobileRequestStateAuthOK)
            {
                // Authentication failed, abort the request
                self.requestState = MobileRequestStateAuthError;
                return nil;
            }
        }
        else if (self.requestState == MobileRequestStateAuthOK)
        {
            NSMutableURLRequest *newRequest = [self.initialRequest mutableCopy];
            newRequest.URL = [request URL];
            request = newRequest;
        }
    }
    
    self.activeRequest = request;
    return request;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (self.contentData) {
        [self.contentData setLength:0];
    } else {
        self.contentData = [NSMutableData data];
    }
    
    self.contentType = [response MIMEType];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.contentData) {
        [self.contentData appendData:data];
    } else {
        self.contentData = [NSMutableData data];
    }
    
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.progressBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.progressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}


#pragma mark -- State Dependent methods
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
    
    switch (self.requestState)
    {
        case MobileRequestStateWAYF:
        {
            if (self.loginViewController == nil)
            {
                [gSecureStateTracker suspendQueue];
                if (gSecureStateTracker.authenticationBlock == nil)
                {
                    [gSecureStateTracker addBlockToQueue:^(BOOL canceled) {
                        if (canceled || self.isCancelled)
                        {
                            // Authentication is required but the user canceled
                            // the last authentication attempt and the timeout has
                            // not been triggered yet. Abort the request.
                            self.requestError = [NSError errorWithDomain:MobileWebErrorDomain
                                                                    code:MobileWebInvalidLoginError
                                                                userInfo:nil];
                            [self cancel];
                            return;
                        }
                        else
                        {
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
                                
                                if (useMitIdp)
                                {
                                    idp = @"https://idp.mit.edu/shibboleth";
                                }
                                else
                                {
                                    idp = @"https://idp.touchstonenetwork.net/shibboleth-idp";
                                }
                                
                                NSString *body = [NSString stringWithFormat:@"user_idp=%@", [idp urlEncodeUsingEncoding:NSUTF8StringEncoding
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
                }
                else
                {
                    [gSecureStateTracker addBlockToQueue:^(BOOL canceled) {
                        if (canceled || self.isCancelled)
                        {
                            // Authentication is required but the user canceled
                            // the last authentication attempt and the timeout has
                            // not been triggered yet. Abort the request.
                            self.requestError = [NSError errorWithDomain:MobileWebErrorDomain
                                                                    code:MobileWebInvalidLoginError
                                                                userInfo:nil];
                            [self cancel];
                            return;
                        }
                        else
                        {
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
            TouchstoneResponse *response = [[TouchstoneResponse alloc] initWithRequest:self.activeRequest
                                                                                  data:self.contentData];
            
            if (response.error)
            {
                if (response.error.code == MobileWebInvalidLoginError)
                {
                    if (self.presetCredentials)
                    {
                        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                             code:NSURLErrorUserAuthenticationRequired
                                                         userInfo:nil];
                        [self connection:connection didFailWithError:error];
                    }
                    else
                    {
                        self.touchstonePassword = nil;
                        if (self.loginViewController == nil)
                        {
                            [self displayLoginPrompt:YES];
                        }
                        else
                        {
                            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                                [self.loginViewController authenticationDidFailWithError:@"Please enter a valid username and password."
                                                                               willRetry:YES];
                            });
                        }
                    }
                }
                else
                {
                    [self connection:connection didFailWithError:response.error];
                }
            }
            else if (response.isSAMLAssertion == NO)
            {
                NSString *tsUsername = [self.touchstoneUser stringByReplacingOccurrencesOfString:@"@mit.edu"
                                                                                      withString:@""
                                                                                         options:NSCaseInsensitiveSearch
                                                                                           range:NSMakeRange(0, [self.touchstoneUser length])];
                
                NSString *body = [NSString stringWithFormat:@"%@=%@&%@=%@",
                                  [response.userFieldName urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [tsUsername urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES],
                                  [response.passwordFieldName urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                  [self.touchstonePassword urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                
                DLog(@"Got POST URL: %@", response.touchstoneURL);
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:response.touchstoneURL];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
                [wayfRequest setValue:@"application/x-www-form-urlencoded"
                   forHTTPHeaderField:@"Content-Type"];
                
                [self transitionToState:MobileRequestStateIDP
                        willSendRequest:wayfRequest];
            }
            else
            {
                self.touchstoneUser = nil;
                self.touchstonePassword = nil;
                gSecureStateTracker.authenticationBlock = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.loginViewController authenticationDidSucceed];
                });
                
                
                NSMutableArray *parameters = [NSMutableArray array];
                for (NSString *name in response.touchstoneParameters)
                {
                    NSString *value = [response.touchstoneParameters objectForKey:name];
                    
                    [parameters addObject:[NSString stringWithFormat:@"%@=%@",
                                           [name urlEncodeUsingEncoding:NSUTF8StringEncoding],
                                           [value urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
                }
                
                
                NSMutableURLRequest *wayfRequest = [NSMutableURLRequest requestWithURL:response.touchstoneURL];
                [wayfRequest setHTTPMethod:@"POST"];
                [wayfRequest setHTTPBody:[[parameters componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
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
    self.contentData = nil;
    if (self.requestError == nil) {
        self.requestError = error;
    }
    
    gSecureStateTracker.authenticationBlock = nil;
    
    [self finish];
}


#pragma mark - MobileRequestLoginView Delegate Methods
- (void)loginRequest:(MobileRequestLoginViewController *)view didEndWithUsername:(NSString *)username password:(NSString *)password shouldSaveLogin:(BOOL)saveLogin
{
    NSString *chompedUser = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.touchstoneUser = chompedUser;
    self.touchstonePassword = password;
    
    if (saveLogin)
    {
        MobileKeychainSetItem(MobileLoginKeychainIdentifier, username, password);
    }
    else
    {
        NSDictionary *mobileCredentials = MobileKeychainFindItem(MobileLoginKeychainIdentifier, NO);
        
        if ([mobileCredentials objectForKey:(__bridge id) kSecAttrAccount])
        {
            MobileKeychainSetItem(MobileLoginKeychainIdentifier, username, @"");
        }
        else
        {
            MobileKeychainDeleteItem(MobileLoginKeychainIdentifier);
        }
    }
    
    [gSecureStateTracker dispatchAuthenticationBlock];
}

- (void)cancelWasPressedForLoginRequest:(MobileRequestLoginViewController *)view
{
    [gSecureStateTracker userCanceledAuthentication];
    self.requestError = [NSError errorWithDomain:MobileWebErrorDomain
                                            code:NSUserCancelledError
                                        userInfo:nil];
    [MobileRequestOperation clearAuthenticatedSession];
    [self cancel];
}
@end
