#import <objc/runtime.h>

#import "MITTouchstoneRequestOperation.h"
#import "MITTouchstoneOperation.h"
#import "MITTouchstoneConstants.h"
#import "MITTouchstoneController.h"
#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneDefaultLoginViewController.h"

#import "MITAdditions.h"

//#define AFNETWORKING_20

#if defined(AFNETWORKING_20)

static dispatch_queue_t touchstone_request_operation_processing_queue() {
    static dispatch_queue_t touchstone_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        touchstone_request_operation_processing_queue = dispatch_queue_create("edu.mit.mobile.touchstone-request.processing", DISPATCH_QUEUE_CONCURRENT);
    });

    return touchstone_request_operation_processing_queue;
}

static dispatch_group_t touchstone_request_operation_completion_group() {
    static dispatch_group_t touchstone_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        touchstone_request_operation_completion_group = dispatch_group_create();
    });

    return touchstone_request_operation_completion_group;
}

#endif //AFNETWORKING_20

static NSString *MITTouchstoneRequestUserAgentKey = @"MITTouchstoneRequestUserAgentKey";


@interface AFURLConnectionOperation ()
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@end

@implementation MITTouchstoneRequestOperation {
    BOOL _isRetryingRequestAfterLoginAttempt;
}

+ (void)setUserAgent:(NSString*)userAgent
{
    objc_setAssociatedObject(self, (__bridge const void*)MITTouchstoneRequestUserAgentKey, userAgent, OBJC_ASSOCIATION_COPY);
}

+ (NSString*)userAgent
{
    return objc_getAssociatedObject(self,(__bridge const void*)MITTouchstoneRequestUserAgentKey);
}

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
    NSMutableURLRequest *touchstoneRequest = [urlRequest mutableCopyTouchstoneAdvertised];

    if ([MITTouchstoneRequestOperation userAgent]) {
        [touchstoneRequest setValue:[MITTouchstoneRequestOperation userAgent] forKey:@"User-Agent"];
    }

    self = [super initWithRequest:touchstoneRequest];

    if (self) {
        
    }

    return self;
}


#if defined(AFNETWORKING_20)
- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
{
    __weak MITTouchstoneRequestOperation *weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (success) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // If all else fails, just send back the data
                // object we got.
                success(blockSelf,responseObject);
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (failure) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // If all else fails, just send back the data
                // object we got.
                failure(blockSelf,error);
            }];
        }
    }];
}

#else

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
{
    __weak MITTouchstoneRequestOperation *weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData *data) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else {
            NSString *contentType = [operation.response MIMEType];
            NSError *jsonError = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

            BOOL jsonDataExpected = [contentType containsSubstring:@"application/json" options:NSCaseInsensitiveSearch];

            // If the content type says the response was JSON and it doesn't parse
            // consider this request a failure and spit back the JSON error.
            if (jsonDataExpected && jsonError) {
                if (failure) {
                    failure(blockSelf,jsonError);
                }
            } else if (jsonObject) {
                // If our response was successfully parsed as JSON, give it back!
                // Note: This behavior is required at the moment since the pre-V3
                // Mobile API did not properly set its content types and older
                // code depends on this behavior
                if (success) {
                    success(blockSelf,jsonObject);
                }
            } else if (success) {
                // If all else fails, just send back the data
                // object we got.
                success(blockSelf,data);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (failure) {
            failure(blockSelf,error);
        }
    }];
}

#endif

- (void)pause:(BOOL)useHTTPRange
{
    [self.lock lock];

    if (useHTTPRange) {
        [super pause];
    } else {
        // Save the request (since AFHTTPRequestOperation likes to use
        // HTTP-Range)
        NSURLRequest *request = self.request;
        [super pause];

        // And restore the original request after -[AFHTTPRequestOperation] messes with it
        self.request = request;

        // Clear the output stream otherwise we end up crashing, hard.
        self.outputStream = [NSOutputStream outputStreamToMemory];
    }

    [self.lock unlock];
}

// A better option here would be to override connection:didReceiveResponse:
// but there appears to be an issue (probably threading) with AFURLConnectionOperation
// which results in the outputStream sucking up enormous (1-2GB+) amount of memory
// followed by the app dying.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *headerFields = [(NSHTTPURLResponse*)self.response allHeaderFields];
    NSString *contentType = headerFields[@"Content-Type"];
    NSRange matchingRange = [contentType rangeOfString:MITECPMIMEType options:NSCaseInsensitiveSearch];

    NSError *error = nil;

    if (matchingRange.location != NSNotFound) {
        if (_isRetryingRequestAfterLoginAttempt) {
            // Just fail, we already tried to log in once
            error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:nil];
        } else if (![MITTouchstoneController sharedController]) {
            NSLog(@"MITTouchstoneController has not been configured, aborting login attempt");
            error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
        } else {
            // Make sure -pause is called before forwarding the connectionDidFinishLoading:
            // call so that AFURLRequestOperation doesn't actually transition to the finished state
            // (since paused -> finished is an illegal transition)
            [self pause:NO];
            NSLog(@"initiating Touchstone login");

            __weak MITTouchstoneRequestOperation *weakSelf = self;
            [[MITTouchstoneController sharedController] login:^{
                MITTouchstoneRequestOperation *blockSelf = weakSelf;
                if (blockSelf) {
                    // Ensure that the operation is out of the paused state
                    // otherwise it will ignore the cancel (and the resultng connection:didFailWithError: call)
                    _isRetryingRequestAfterLoginAttempt = YES;
                    [blockSelf resume];
                }
            }];
        }
    }

    if (error) {
        [self connection:connection didFailWithError:error];
    } else {
        [super connectionDidFinishLoading:connection];
    }
}

@end
