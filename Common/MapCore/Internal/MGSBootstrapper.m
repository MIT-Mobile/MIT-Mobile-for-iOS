#import "MGSBootstrapper.h"
#import "MobileRequestOperation.h"

@interface MGSBootstrapper ()
@property (strong) NSOperationQueue *requestQueue;
@property (strong) NSDictionary *cachedResponse;
@property (strong) NSError *cachedError;
@property (strong) NSDate *lastRetrieved;
@property (assign) NSTimeInterval cacheExpiryInterval;
@property (assign,getter=isRequestInFlight) BOOL requestInFlight;
@end

@implementation MGSBootstrapper
+ (id)sharedBootstrapper
{
    static MGSBootstrapper *bootstrapper = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bootstrapper = [[MGSBootstrapper alloc] init];
    });
    
    return bootstrapper;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.requestQueue = [[NSOperationQueue alloc] init];
        self.requestQueue.maxConcurrentOperationCount = 1;
        self.cachedResponse = nil;
        self.lastRetrieved = [NSDate distantPast];
        self.cacheExpiryInterval = 60.0 * 5.0; // 5 Minute cache
    }
    
    return self;
}

- (void)validateResponse:(id)content
                   error:(NSError**)error
{
    NSString* contentClass = @"NSDictionary";

    if ([content isKindOfClass:NSClassFromString(contentClass)]) {
        NSDictionary *bootstrap = (NSDictionary*)content;
        NSDictionary *basemaps = bootstrap[@"basemaps"];
        
        if ([basemaps count]) {
            [basemaps enumerateKeysAndObjectsUsingBlock:^(NSString *setName, id obj, BOOL *stop) {
                NSString *objectClass = @"NSArray";
                if ([obj isKindOfClass:NSClassFromString(objectClass)] == NO) {
                    (*stop) = YES;
                    NSString *errorDescription = [NSString stringWithFormat:@"invalid set type, expected %@, received %@",
                                                  objectClass, NSStringFromClass([obj class])];
                    (*error) = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorBadServerResponse
                                               userInfo:@{ NSLocalizedDescriptionKey : errorDescription }];
                }
            }];
        } else {
            (*error) = [NSError errorWithDomain:NSURLErrorDomain
                                           code:NSURLErrorBadServerResponse
                                       userInfo:@{ NSLocalizedDescriptionKey : @"missing or malformed 'basemaps' key" }];
        }
    } else {
        NSString *errorDescription = [NSString stringWithFormat:@"invalid content type, expected %@, received %@",
                                      contentClass, NSStringFromClass([content class])];
        (*error) = [NSError errorWithDomain:NSURLErrorDomain
                                       code:NSURLErrorBadServerResponse
                                   userInfo:@{ NSLocalizedDescriptionKey : errorDescription }];
    }
}



// TODO: This code could be grealy simplified if we don't care if there
// are multiple requests
- (void)requestBootstrap:(void (^)(NSDictionary*,NSError*))resultBlock
{
    void (^requestResultBlock)(NSDictionary*,NSError*) = [resultBlock copy];
    
    [self.requestQueue addOperationWithBlock:^{
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.lastRetrieved];
        BOOL needsUpdate = ((interval > self.cacheExpiryInterval) ||
                            (self.cachedResponse == nil) ||
                            (self.cachedError));
        
        if (!(needsUpdate && (self.requestInFlight == NO))) {
            DDLogVerbose(@"Using bootstrap retreived at %@", self.lastRetrieved);
            if (requestResultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                        requestResultBlock(self.cachedResponse,self.cachedError);
                });
            }
        } else {
            DDLogVerbose(@"Requesting fresh copy of the bootstrap");
            MobileRequestOperation* operation = [MobileRequestOperation operationWithModule:@"map"
                                                                                    command:@"bootstrap"
                                                                                 parameters:nil];
            [operation setCompleteBlock:^(MobileRequestOperation* blockOperation, id content, NSString* contentType, NSError* error) {
                NSError *localError = error;
                if (localError == nil) {
                    [self validateResponse:content
                                     error:&localError];
                }
                
                
                if (localError) {
                    self.cachedError = error;
                    self.cachedResponse = nil;
                } else {
                    self.cachedResponse = content;
                    self.cachedError = nil;
                }
                
                self.lastRetrieved = [NSDate date];
                self.requestInFlight = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestResultBlock) {
                        requestResultBlock(self.cachedResponse,self.cachedError);
                    }
                });
            }];
            
            self.requestInFlight = YES;
            [[NSOperationQueue currentQueue] addOperation:operation];
        }
    }];
}

@end
