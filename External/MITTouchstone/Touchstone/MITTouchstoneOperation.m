#import "MITTouchstoneOperation.h"
#import "AFHTTPRequestOperation.h"

#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneConstants.h"

#import "MITECPResponseMessage.h"
#import "MITECPAuthnRequestMessage.h"

NSString* const MITECPErrorDomain = @"MITECPErrorDomain";

@interface MITTouchstoneOperation ()
@property (getter = isSuccess) BOOL success;
@property (nonatomic,getter = isFinished) BOOL finished;
@property (nonatomic,getter = isExecuting) BOOL executing;

@property (nonatomic,strong) id<MITIdentityProvider> identityProvider;
@property (nonatomic,strong) NSError *error;
@property (nonatomic,strong) NSURLCredential *credential;

@property (nonatomic,strong) NSOperationQueue *requestOperationQueue;

// Even if the operation that called us disappears, we should either complete
// the current authentication request or fail gracefully in the start method
@property (nonatomic,weak) AFURLConnectionOperation *requestingOperation;
@property (nonatomic,copy) NSURLRequest *originalRequest;

// State tracking for the currently in-flight request
@property (nonatomic,strong) AFHTTPRequestOperation *requestOperation;
@end

@implementation MITTouchstoneOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize response = _response;
@synthesize responseData = _responseData;

+ (NSOperationQueue*)touchstoneRequestQueue
{
    static NSOperationQueue *touchstoneOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        touchstoneOperationQueue = [[NSOperationQueue alloc] init];
        touchstoneOperationQueue.name = @"edu.mit.mobile.touchstone-requests";
        touchstoneOperationQueue.maxConcurrentOperationCount = 1;
    });
    
    return touchstoneOperationQueue;
}

- (instancetype)initWithRequestOperation:(AFURLConnectionOperation*)requestingOperation identityProvider:(id<MITIdentityProvider>)identityProvider credential:(NSURLCredential*)credential
{
    self = [super init];
    if (self) {
        _requestingOperation = requestingOperation;
        _originalRequest = [requestingOperation.request copy];
        
        _identityProvider = identityProvider;
        _credential = credential;
    }
    
    return  self;
}

- (instancetype)initWithRequest:(NSURLRequest*)request identityProvider:(id<MITIdentityProvider>)identityProvider credential:(NSURLCredential*)credential
{
    self = [super init];
    if (self) {
        _originalRequest = [request copy];
        _identityProvider = identityProvider;
        _credential = credential;
    }
    
    return self;
}

#pragma mark - NSOperation
#pragma mark State
- (BOOL)isConcurrent
{
    return YES;
}

- (void)setExecuting:(BOOL)executing
{
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setFinished:(BOOL)finished
{
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)start
{
    self.requestOperation = nil;
    
    if ([self isCancelled]) {
        [self.requestOperationQueue addOperationWithBlock:^{
            [self operationDidFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain
                                                                code:NSUserCancelledError
                                                            userInfo:nil]];
        }];
    } else {
        self.executing = YES;
        self.finished = NO;
        
        [self.requestOperationQueue addOperationWithBlock:^{
            [self main];
        }];
    }
}

- (void)main
{
    NSOperation *initialOperation = nil;
    
    if (self.requestingOperation.response && self.requestingOperation.responseData) {
        initialOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self handleServiceProviderResponse:(NSHTTPURLResponse*)self.requestingOperation.response
                                   responseData:self.requestingOperation.responseData];
        }];
    } else {
        NSURLRequest *request = nil;
        if (self.requestingOperation.request) {
            request = self.requestingOperation.request;
        } else if (self.originalRequest) {
            request = self.originalRequest;
        }
        
        if (request) {
            NSMutableURLRequest *mutableRequest = [request mutableCopy];
            [mutableRequest setAdvertisesECP];
            
            // Make sure we ignore any existing cookies on this initial request
            // so we can be certain that we are performing a new login and not
            // just re-using an existing one. We don't want to use
            // HTTPShouldHandleCookies because we need any cookies in the response
            // to be processed
            [mutableRequest setValue:@"" forHTTPHeaderField:@"Cookie"];
            initialOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self dispatchURLRequest:mutableRequest
                     allowAuthentication:NO
                              completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                                  [self handleServiceProviderResponse:response
                                                         responseData:responseData];
                }];
            }];
        }
    }

    if (initialOperation) {
        [self.requestOperationQueue addOperation:initialOperation];
    } else {
        // Absolutely nothing useful we can do. No error occurred but
        // we can't say we succeeded, either.
        // TODO: treat this as an error?
        [self operationDidFailWithError:nil];
    }
}

- (void)operationDidSucceedWithResponse:(NSHTTPURLResponse*)response data:(NSData*)responseData
{
    self.success = YES;
    self.error = nil;
    
    _response = response;
    _responseData = responseData;
    
    [self finish];
}

- (void)operationDidFailWithError:(NSError*)error
{
    self.success = NO;
    self.error = error;
    
    _response = nil;
    _responseData = nil;
    
    [self finish];
}

- (void)finish
{
    self.executing = NO;
    self.finished = YES;
}

#pragma mark Lifecycle
- (NSOperationQueue*)requestOperationQueue
{
    if (!_requestOperationQueue) {
        _requestOperationQueue = [[NSOperationQueue alloc] init];
        _requestOperationQueue.name = [NSString stringWithFormat:@"edu.mit.mobile.touchstone-requests.%@",self];
        _requestOperationQueue.maxConcurrentOperationCount = 1;
    }
    
    return _requestOperationQueue;
}

- (void)handleServiceProviderResponse:(NSHTTPURLResponse*)response responseData:(NSData*)responseData
{
    NSDictionary *responseHeaders = [response allHeaderFields];
    NSRange matchingRange = [responseHeaders[@"Content-Type"] rangeOfString:MITECPMIMEType options:NSCaseInsensitiveSearch];
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    } else if (matchingRange.location != NSNotFound) {
        [self handleECPAuthnRequestWithResponse:response
                                   responseData:responseData];
    } else {
        [self operationDidSucceedWithResponse:response data:responseData];
    }
}

- (void)handleECPAuthnRequestWithResponse:(NSHTTPURLResponse*)response responseData:(NSData*)responseData
{
    NSParameterAssert(response);
    NSParameterAssert(responseData);
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    }

// warning added by bskinner - 2014.04.15
#warning The flow here does not match the ECP spec. Any errors should be forwarded back to the SP as a SOAP fault
    MITECPAuthnRequestMessage *serviceProviderMessage = [[MITECPAuthnRequestMessage alloc] initWithData:responseData];
    
    if (!serviceProviderMessage || serviceProviderMessage.error) {
        [self operationDidFailWithError:serviceProviderMessage.error];
        return;
    } else if (!self.credential) {
        // If we don't have any credentials set and we received a SOAP mesage
        // we need to bail; we will be asked for our credentials following this request.
        // Continuing the request should end up at the same result, we just reach
        // it here with one less request.
        // [bskinner - 2014.04.06]
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:nil];
        [self operationDidFailWithError:error];
        return;
    }
    
    
    NSLog(@"response consumer: %@",serviceProviderMessage.responseConsumerURL);
    
    NSURLRequest *identityProviderRequest = [serviceProviderMessage nextRequestWithURL:self.identityProvider.URL];
    [self dispatchURLRequest:identityProviderRequest
         allowAuthentication:YES
                  completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                      [self handleECPResponseWithResponse:response responseData:responseData authnRequest:serviceProviderMessage];
                  }];
}

- (void)handleECPResponseWithResponse:(NSHTTPURLResponse*)response responseData:(NSData*)responseData authnRequest:(MITECPAuthnRequestMessage*)serviceProviderMessage;
{
    NSAssert(serviceProviderMessage, @"fatal error: ECP messages out of order");
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    }
    
    MITECPResponseMessage *identityProviderMessage = [[MITECPResponseMessage alloc] initWithData:responseData
                                                                                                        relayState:serviceProviderMessage.relayState];
    if (!identityProviderMessage || identityProviderMessage.error) {
        [self operationDidFailWithError:identityProviderMessage.error];
        return;
    }
    
    NSLog(@"assertion consumer: %@",identityProviderMessage.assertionConsumerServiceURL);
    if (![serviceProviderMessage.responseConsumerURL isEqual:identityProviderMessage.assertionConsumerServiceURL]) {
        NSLog(@"aborting, potential MITM detected");
        
        //TODO: Send a SOAP fault to the SP
        NSError *canceledError = [NSError errorWithDomain:NSURLErrorDomain
                                                     code:NSURLErrorUserCancelledAuthentication
                                                 userInfo:nil];
        [self operationDidFailWithError:canceledError];
        return;
    }
    
    NSURLRequest *spRequest = [identityProviderMessage nextRequestWithURL:identityProviderMessage.assertionConsumerServiceURL];

    [self dispatchURLRequest:spRequest
         allowAuthentication:NO
                  completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                      [self operationDidSucceedWithResponse:response data:responseData];
                  }];
}


- (void)dispatchURLRequest:(NSURLRequest*)request allowAuthentication:(BOOL)enableHTTPAuth completion:(void (^)(NSHTTPURLResponse *response, NSData *responseData))completion
{
    NSParameterAssert(request);
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    if (enableHTTPAuth) {
        // If the IdP implements the localUserForUser: method, use that as a hint
        // that it needs to do some mangling of the user in order to get things
        // to work correctly when actually authenticating. At this point, this is
        // primarily for supporting the MIT IdP (see the MITIdentityProvider header
        // for more details as to why).
        // [bskinner - 2014.04.08]
        if ([self.identityProvider respondsToSelector:@selector(localUserForUser:)]) {
            requestOperation.credential = [[NSURLCredential alloc] initWithUser:[self.identityProvider localUserForUser:self.credential.user]
                                                                       password:self.credential.password
                                                                    persistence:NSURLCredentialPersistenceNone];
        } else {
            requestOperation.credential = self.credential;
        }
    } else {
        requestOperation.shouldUseCredentialStorage = NO;
        requestOperation.credential = nil;
    }
    
    requestOperation.shouldUseCredentialStorage = NO;

    __weak MITTouchstoneOperation *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        MITTouchstoneOperation *blockSelf = weakSelf;
        [self.requestOperationQueue addOperationWithBlock: ^{
            if (blockSelf) {
                if (completion) {
                    completion(operation.response,operation.responseData);
                } else {
                    NSLog(@"a completion handler was not passed, this may result in undesired behavior");
                }
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MITTouchstoneOperation *blockSelf = weakSelf;
        [self.requestOperationQueue addOperationWithBlock: ^{
            if (blockSelf) {
                NSHTTPURLResponse *response = operation.response;
                if (response.statusCode == 401) {
                    NSError *error = nil;
                    if (operation.error.code != NSURLErrorUserAuthenticationRequired) {
                        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:nil];
                    } else {
                        error = operation.error;
                    }

                    [self operationDidFailWithError:error];
                } else {
                    [self operationDidFailWithError:error];
                }
            }
        }];
    }];
    
    [self.requestOperationQueue addOperation:requestOperation];
}

@end
