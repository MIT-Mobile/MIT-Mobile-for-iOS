#import "MITTouchstoneOperation.h"
#import "AFHTTPRequestOperation.h"

#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneConstants.h"

#import "MITECPIdentityProviderResponse.h"
#import "MITECPServiceProviderResponse.h"

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

- (instancetype)initWithRequestOperation:(AFURLConnectionOperation*)requestingOperation
{
    return [self initWithRequestOperation:requestingOperation identityProvider:nil credential:nil];
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


- (instancetype)initWithRequest:(NSURLRequest*)request
{
    return [self initWithRequest:request identityProvider:nil credential:nil];
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

#pragma mark Setup
- (void)setCredential:(NSURLCredential*)credential withIdentityProvider:(id<MITIdentityProvider>)identityProvider
{
    if (![self isExecuting]) {
        _credential = credential;
        _identityProvider = identityProvider;
    };
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
            [self handleInitiatingResponseFromServiceProvider:(NSHTTPURLResponse*)self.requestingOperation.response
                                             withResponseData:self.requestingOperation.responseData];
        }];
    } else {
        NSURLRequest *request = nil;
        if (self.requestingOperation.request) {
            request = self.requestingOperation.request;
        } else if (self.originalRequest) {
            request = self.originalRequest;
        }
        
        if (request) {
            initialOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self dispatchURLRequest:request
                     allowAuthentication:NO
                  advertiseShibbolethECP:YES
                              completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                                  [self handleInitiatingResponseFromServiceProvider:response
                                                                   withResponseData:responseData];
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

- (void)operationDidSucceed:(BOOL)success withResponse:(NSHTTPURLResponse*)response data:(NSData*)responseData
{
    self.success = success;
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

- (void)handleInitiatingResponseFromServiceProvider:(NSHTTPURLResponse*)response withResponseData:(NSData*)responseData
{
    NSDictionary *responseHeaders = [response allHeaderFields];
    NSRange matchingRange = [responseHeaders[@"Content-Type"] rangeOfString:MITECPMIMEType options:NSCaseInsensitiveSearch];
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    } else if (matchingRange.location != NSNotFound) {
        [self handleResponseFromServiceProvider:response
                               withResponseData:responseData];
    } else {
        [self operationDidSucceed:YES withResponse:response data:responseData];
    }
}

- (void)handleResponseFromServiceProvider:(NSHTTPURLResponse*)response withResponseData:(NSData*)responseData
{
    NSParameterAssert(response);
    NSParameterAssert(responseData);
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    }
    
    MITECPServiceProviderResponse *serviceProviderMessage = [[MITECPServiceProviderResponse alloc] initWithData:responseData];
    
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
      advertiseShibbolethECP:NO
                  completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                      [self handleResponseFromIdentityProvider:response withResponseData:responseData serviceProviderMessage:serviceProviderMessage];
                  }];
}

- (void)handleResponseFromIdentityProvider:(NSHTTPURLResponse*)response withResponseData:(NSData*)responseData serviceProviderMessage:(MITECPServiceProviderResponse*)serviceProviderMessage;
{
    NSAssert(serviceProviderMessage, @"fatal error: ECP messages out of order");
    
    if (self.isCancelled) {
        [self operationDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorUserCancelledAuthentication
                                                        userInfo:nil]];
        return;
    }
    
    MITECPIdentityProviderResponse *identityProviderMessage = [[MITECPIdentityProviderResponse alloc] initWithData:responseData
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
      advertiseShibbolethECP:NO
                  completion:^(NSHTTPURLResponse *response, NSData *responseData) {
                      [self operationDidSucceed:YES withResponse:response data:responseData];
                  }];
}


- (void)dispatchURLRequest:(NSURLRequest*)request allowAuthentication:(BOOL)enableHTTPAuth advertiseShibbolethECP:(BOOL)advertiseECP completion:(void (^)(NSHTTPURLResponse *response, NSData *responseData))completion
{
    NSParameterAssert(request);
    
    if (advertiseECP) {
        request = [request mutableCopyTouchstoneAdvertised];
    }
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    if (enableHTTPAuth) {
        requestOperation.credential = self.credential;
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
                    [self operationDidSucceed:NO withResponse:response data:nil];
                } else {
                    [self operationDidFailWithError:error];
                }
            }
        }];
    }];
    
    [self.requestOperationQueue addOperation:requestOperation];
}

@end
