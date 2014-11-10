#import <objc/runtime.h>
#import <RestKit/RKHTTPUtilities.h>

#import "MITTouchstoneRequestOperation.h"
#import "MITTouchstoneOperation.h"
#import "MITTouchstoneConstants.h"
#import "MITTouchstoneController.h"
#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneDefaultLoginViewController.h"
#import "MITAdditions.h"

static NSString *MITTouchstoneRequestUserAgentKey = @"MITTouchstoneRequestUserAgentKey";

// Find a way around this. Even though nearly all of the ancestors of this
// class do this as well, it is a *really* bad practice.
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
    NSMutableURLRequest *touchstoneRequest = [urlRequest mutableCopy];
    [touchstoneRequest setAdvertisesECP];
    
    if ([MITTouchstoneRequestOperation userAgent]) {
        [touchstoneRequest setValue:[MITTouchstoneRequestOperation userAgent] forKey:@"User-Agent"];
    }

    self = [super initWithRequest:touchstoneRequest];

    if (self) {
        [self setAcceptableStatusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    }

    return self;
}

- (void)setCompletionBlockWithSuccess:(void (^)(MITTouchstoneRequestOperation *operation, id responseObject))success
                              failure:(void (^)(MITTouchstoneRequestOperation *operation, NSError *error))failure;
{

    // Wrap the failure and success blocks so we don't have a ton of unnecessary if(failure) and if(success)
    // statements in the setCompletionBlock... call below
    void (^safeSuccessBlock)(MITTouchstoneRequestOperation*, id) = ^(MITTouchstoneRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation,responseObject);
        }
    };

    void (^safeFailureBlock)(MITTouchstoneRequestOperation*, NSError*) = ^(MITTouchstoneRequestOperation *operation, NSError *error) {
        DDLogWarn(@"request to '%@' failed with error: %@", operation.request.URL, [error localizedDescription]);

        if (failure) {
            failure(operation,error);
        }
    };

    __weak MITTouchstoneRequestOperation *weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData *data) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        MITBlockAssert(blockSelf,(data == nil) || [data isKindOfClass:[NSData class]],@"expected response object of type %@ but got %@. Something is doing some unexpected preprocessing of the responseObject",NSStringFromClass([NSData class]),NSStringFromClass([data class]));

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
                safeFailureBlock(blockSelf,jsonError);
            } else if (jsonObject) {
                // If our response was successfully parsed as JSON, give it back!
                // Note: This behavior is required at the moment since the pre-V3
                // Mobile API did not properly set its content types and older
                // code depends on this behavior
                safeSuccessBlock(blockSelf,jsonObject);
            } else {
                // If all else fails, just send back the data
                // object we got.
                safeSuccessBlock(blockSelf,data);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MITTouchstoneRequestOperation *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else {
            safeFailureBlock(blockSelf,error);
        }
    }];
}

- (NSSet *)acceptableContentTypes
{
    // Necessary to handle error between restKit and touchstone operations.
    NSMutableSet *acceptableContentTypes = [[super acceptableContentTypes] mutableCopy];
    [acceptableContentTypes addObject:MITECPMIMEType];
    return acceptableContentTypes;
}

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

    if (contentType && matchingRange.location != NSNotFound) {
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
            [[MITTouchstoneController sharedController] login:^(BOOL success, NSError *error) {
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
