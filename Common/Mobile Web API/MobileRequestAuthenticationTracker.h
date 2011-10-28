#import <Foundation/Foundation.h>

@interface MobileRequestAuthenticationTracker : NSObject {
    BOOL _userCanceledAuthentication;
}

@property (copy) void (^authenticationBlock)(void);
@property NSTimeInterval cancellationTimeout;

- (void)addBlockToQueue:(void(^)(BOOL canceled))block;
- (void)suspendQueue;
- (void)resumeQueue;

- (void)dispatchAuthenticationBlock;
- (void)userCanceledAuthentication;
@end
