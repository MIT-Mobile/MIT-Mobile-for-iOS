#import "MobileRequestAuthenticationTracker.h"

@interface MobileRequestAuthenticationTracker ()
@property BOOL authenticationCanceled;
@property (nonatomic,retain) NSOperationQueue* operationQueue;
@property (readonly) BOOL queueIsSuspended;
@property NSInteger queueSuspendCount;
@end

@implementation MobileRequestAuthenticationTracker
@synthesize authenticationBlock = _authenticationBlock;
@synthesize cancellationTimeout = _cancellationTimeout;
@synthesize operationQueue = _operationQueue;
@synthesize queueSuspendCount = _queueSuspendCount;
@synthesize authenticationCanceled = _authenticationCanceled;

@dynamic queueIsSuspended;

- (id)init {
    self = [super init];
    
    if (self) {
        self.cancellationTimeout = 0.00;
        self.authenticationCanceled = NO;
        self.queueSuspendCount = 0;
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.operationQueue setMaxConcurrentOperationCount:1];
    }
    
    return self;
}

- (void)addBlockToQueue:(void (^)(BOOL isCanceled))block {
    NSBlockOperation *operation = [[[NSBlockOperation alloc] init] autorelease];
    [operation addExecutionBlock:^ {
            block((self.authenticationCanceled || [operation isCancelled]));
    }];
    
    [operation setCompletionBlock:^ {
        if ([operation isCancelled]) {
            block(YES);
        }
    }];
    
    [self.operationQueue addOperation:operation];
}
     
- (void)suspendQueue {
    self.queueSuspendCount += 1;
    
    if (self.queueSuspendCount > 0) {
        [self.operationQueue setSuspended:YES];
    }
}

- (void)resumeQueue {
    if (self.queueSuspendCount > 0) {
        self.queueSuspendCount -= 1;
    }
    
    if (self.queueSuspendCount == 0) {
        [self.operationQueue setSuspended:NO];
    }
}

- (BOOL)queueIsSuspended {
    return [self.operationQueue isSuspended];
}

- (void)dispatchAuthenticationBlock
{
    if (self.authenticationBlock)
    {
        dispatch_queue_t authQueue = dispatch_queue_create(NULL, 0);
        dispatch_async(authQueue,self.authenticationBlock);
        dispatch_release(authQueue);
    }
}

- (void)userCanceledAuthentication {
    static dispatch_queue_t localQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localQueue = dispatch_queue_create(NULL, 0);
    });
    
    dispatch_sync(localQueue, ^(void) {
        if ((self.authenticationCanceled == NO) && (self.cancellationTimeout > 0)) {
            self.authenticationCanceled = YES;
            
            double delayInSeconds = self.cancellationTimeout;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, localQueue, ^(void) {
                self.authenticationCanceled = NO;
            });
        } else {
            [self.operationQueue cancelAllOperations];
        }
    });
    
    self.authenticationBlock = nil;
}

@end
