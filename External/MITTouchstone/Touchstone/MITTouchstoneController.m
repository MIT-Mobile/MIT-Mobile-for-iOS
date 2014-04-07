#import <objc/runtime.h>

#import "MITTouchstoneController.h"
#import "MITTouchstoneIdentityProvider.h"
#import "MITTouchstoneNetworkIdentityProvider.h"
#import "MITTouchstoneDefaultLoginViewController.h"
#import "MITTouchstoneOperation.h"

#pragma mark - Globals
static NSString* const MITTouchstoneLastLoggedInUserKey = @"MITTouchstoneLastLoggedInUser";
static NSString* const MITTouchstoneLoginViewControllerAssociatedObjectKey = @"MITTouchstoneLoginViewControllerAssociatedObject";

#pragma mark - Static
static __weak MITTouchstoneController *_sharedTouchstonController = nil;


#pragma mark - Category Interfaces
@interface MITTouchstoneController () <MITTouchstoneLoginViewControllerDelegate>
@property (nonatomic,copy) NSDictionary *userInformation;

@property (nonatomic,readonly,strong) NSOperationQueue *loginRequestQueue;
@property (nonatomic,readonly,strong) NSOperationQueue *loginCompletionQueue;

// TODO: look into using a serializable object for this information.
// It may not be needed since the lastLoggedInUser (may) be all that is important
@property (nonatomic,copy) NSString *lastLoggedInUser;
@property BOOL lastLoginDidSucceed;
@property (strong) NSError *lastLoginError;

@property (nonatomic,strong) NSURLCredential *credential;
@property (nonatomic,strong) NSURLCredential *savedCredential;
@property (nonatomic,strong) NSRecursiveLock *lock;

- (BOOL)needsToPromptForCredential;
@end

#pragma mark - Main Implementation
@implementation MITTouchstoneController {
    BOOL _needsToSendLoginRequest;
    __weak MITTouchstoneDefaultLoginViewController *_touchstoneLoginViewController;
    __weak MITTouchstoneOperation *_loginRequestOperation;
}

@synthesize credential = _credential;
@synthesize loginCompletionQueue = _loginCompletionQueue;
@synthesize loginRequestQueue = _loginRequestQueue;

#pragma mark Class
+ (instancetype)sharedController
{
    __block MITTouchstoneController *controller = nil;

    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        controller = _sharedTouchstonController;
    });

    return controller;
}

+ (void)setSharedController:(MITTouchstoneController *)sharedController
{
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _sharedTouchstonController = sharedController;
    });
}

+ (NSArray*)allIdentityProviders
{
    static NSArray *identityProviders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Order is important here! Each of the identity providers here will be asked,
        // in turn, if they can perform aunthentication on behalf of the user.
        // The first IdP to respond 'YES' wins
        identityProviders = @[[[MITTouchstoneIdentityProvider alloc] init],
                              [[MITTouchstoneNetworkIdentityProvider alloc] init]];
    });
    
    return [NSArray arrayWithArray:identityProviders];
}

+ (id<MITIdentityProvider>)identityProviderForCredential:(NSURLCredential*)credential
{
    if (!credential) {
        return nil;
    }
    
    NSString *user = credential.user;
    
    __block id<MITIdentityProvider> selectedIdentityProvider = nil;
    [[self allIdentityProviders] enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        if ([identityProvider canAuthenticateForUser:user]) {
            selectedIdentityProvider = identityProvider;
            (*stop) = YES;
        }
    }];
    
    return selectedIdentityProvider;
}

+ (NSURL*)loginEntryPointURL
{
    return [NSURL URLWithString:@"https://mobile-dev.mit.edu/api/?module=libraries&command=getUserIdentity"];
}

#pragma mark - Instance Methods
- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

#pragma mark _Properties
- (void)clearAllCredentials
{
    [[MITTouchstoneController allIdentityProviders] enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        NSURLProtectionSpace *protectionSpace = identityProvider.protectionSpace;
        NSDictionary *allCredentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
        
        [allCredentials enumerateKeysAndObjectsUsingBlock:^(NSString *user, NSURLCredential *credential, BOOL *stop) {
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:protectionSpace];
        }];
    }];
}

- (NSURLCredential*)credential
{
    if (!_credential) {
        NSArray *identityProviders = [MITTouchstoneController allIdentityProviders];
        
        // Grab the first credential we find.
        // Note: This will only work if we keep a single credential stored
        __block NSURLCredential *storedCredential = nil;
        [identityProviders enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
            NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:identityProvider.protectionSpace];
            
            if (credential) {
                storedCredential = credential;
                (*stop) = YES;
            }
        }];
        
        _credential = storedCredential;
    }
    
    return _credential;
}

- (void)setCredential:(NSURLCredential*)credential
{
    if (![_credential isEqual:credential]) {
        _credential = credential;
    }
}

- (NSURLCredential*)savedCredential
{
    NSString *lastLoggedInUser = [[NSUserDefaults standardUserDefaults] stringForKey:MITTouchstoneLastLoggedInUserKey];
    NSURLCredentialStorage *credentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
    __block NSURLCredential *credential = nil;
    
    [[MITTouchstoneController allIdentityProviders] enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        
    }];

    return nil;
}

- (NSOperationQueue*)loginCompletionQueue
{
    if (!_loginCompletionQueue) {
        _loginCompletionQueue = [[NSOperationQueue alloc] init];
        _loginCompletionQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _loginCompletionQueue.name = @"edu.mit.mobile.touchstone.login-completion-queue";
    }

    return _loginCompletionQueue;
}


- (NSOperationQueue*)loginRequestQueue
{
    if (!_loginRequestQueue) {
        _loginRequestQueue = [[NSOperationQueue alloc] init];
        _loginRequestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _loginRequestQueue.name = @"edu.mit.mobile.touchstone.login-request-queue";
    }

    return _loginRequestQueue;
}

#pragma mark _Private
- (void)_login:(void (^)(void))completion
{
    [self.lock lock];

    [self presentLoginViewControllerIfNeeded];
    [self enqueueLoginRequestIfNeeded];

    // Declared early on since this is used in both the operations below
    __weak MITTouchstoneController *weakSelf = self;
    if (completion) {
        [self.loginCompletionQueue addOperationWithBlock:^{
            MITTouchstoneController *blockSelf = weakSelf;
            if (blockSelf) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [blockSelf.lock lock];

                    if (blockSelf.lastLoginDidSucceed) {
                        completion();
                    } else {
                        completion();
                    }

                    [blockSelf.lock unlock];
                }];
            } else {
                NSLog(@"Touchstone controller was prematurely deallocated; be prepared for unforseen consequences.");

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion();
                }];
            }
        }];
    }
    
    [self.lock unlock];
}

- (void)setNeedsToSendLoginRequest
{
    _needsToSendLoginRequest = YES;
}

- (BOOL)needsToSendLoginRequest
{
    return !_loginRequestOperation || _needsToSendLoginRequest;
}

- (void)enqueueLoginRequestIfNeeded
{
    [self.lock lock];

    if ([self needsToSendLoginRequest]) {
        // Immediately suspend the queue for dispatching the completion blocks
        //  (login parameter). This will be resumed after the MITTouchstoneOperation
        //  completes and any waiting connections will be allowed to continue.
        // If this queue is already suspended, this will effectively be a NOP
        self.loginCompletionQueue.suspended = YES;

        // Cancel the pending operation and clear out the login request
        //  tracking ivar. This should stop the operation dead in its tracks
        //  if it hasn't completed yet and, if it has completed, then clearing out
        //  the loginRequestOperation ivar should prevent it from triggering
        //  the side-effects in the completion block (the locking is important here!)
        // Again, if there is no current request operation, this should be a NOP and
        //  not change any of the below behavior.
        NSOperation *currentRequestOperation = _loginRequestOperation;
        _loginRequestOperation = nil;
        [currentRequestOperation cancel];


        NSURLRequest *loginRequest = [[NSURLRequest alloc] initWithURL:[MITTouchstoneController loginEntryPointURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:60.];

        NSURLCredential *credential = self.credential;
        MITTouchstoneOperation *operation = [[MITTouchstoneOperation alloc] initWithRequest:loginRequest
                                                                           identityProvider:[MITTouchstoneController identityProviderForCredential:credential]
                                                                                 credential:credential];
        _loginRequestOperation = operation;

        __weak MITTouchstoneController *weakSelf = self;
        __weak MITTouchstoneOperation *weakOperation = operation;
        operation.completionBlock = ^{
            MITTouchstoneController *blockSelf = weakSelf;
            MITTouchstoneOperation *blockOperation = weakOperation;

            if (blockSelf) {
                [blockSelf.lock lock];

                if (blockSelf->_loginRequestOperation == blockOperation) {
                    if (blockOperation.isSuccess) {
                        NSError *error = nil;
                        NSDictionary *userInformation = [NSJSONSerialization JSONObjectWithData:blockOperation.responseData options:0 error:&error];

                        if (error) {
                            NSLog(@"failed to parse user information from request %@: %@",loginRequest,error);
                        } else {
                            blockSelf.userInformation = userInformation;
                        }

                        NSLog(@"successful login as %@",blockOperation.credential.user);
                        blockSelf.lastLoggedInUser = blockOperation.credential.user;
                        blockSelf.lastLoginError = nil;
                        blockSelf.lastLoginDidSucceed = YES;
                    } else {
                        NSLog(@"login attempt failed as %@",blockOperation.credential.user);
                        blockSelf.lastLoginError = blockOperation.error;
                        blockSelf.lastLoginDidSucceed = NO;
                    }

                    blockSelf->_loginRequestOperation = nil;
                    blockSelf.loginCompletionQueue.suspended = NO;
                }

                [blockSelf.lock unlock];
            }
        };

        [self.loginRequestQueue addOperation:operation];
    }

    [self.lock unlock];
}

- (BOOL)needsToPromptForCredential
{
    NSURLCredential *credential = self.credential;
    
    // Should only be true if the credential is invalid (either self.credential
    // is nil, the user is nil, or the password is nil) and we aren't already prompting
    // the user for their input.
    return !(credential.user && credential.password) || !self.lastLoginDidSucceed;
}

/** Sends a message to the authenticationDelegate to present
 *  a login view controller (if necessary) and suspends the
 *  internal operation queue.
 *
 *  This method needs to be balanced with a call to -dismissLoginViewController;
 */
- (void)presentLoginViewControllerIfNeeded
{
    [self.lock lock];
    if (!_touchstoneLoginViewController && [self needsToPromptForCredential]) {
        self.loginRequestQueue.suspended = YES;
        
        MITTouchstoneDefaultLoginViewController *touchstoneViewController = [[MITTouchstoneDefaultLoginViewController alloc] initWithCredential:self.credential];
        touchstoneViewController.delegate = self;
        _touchstoneLoginViewController = touchstoneViewController;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:touchstoneViewController];
            [self.authenticationDelegate touchstoneController:self presentViewController:navigationController];
            
            // TODO: See if this is even a sane thing to ask at this point. It seems to work
            // in iOS 7 so far. Also look into firing this off as another block on the
            // main queue so we can at least give the main runloop a chance to tick
            if (!([touchstoneViewController presentingViewController] || [touchstoneViewController parentViewController])) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"touchstone login view controller was not added to the view hierarchy"
                                             userInfo:nil];
            }
        }];
    }
    
    [self.lock unlock];
}

/** Sends a message to the authenticationDelegate that it should dismiss the
 *  presented login view controller (if one is currently active) and resumes
 *  the internal operation queue.
 */
- (void)dismissLoginViewController
{
    [self.lock lock];
    
    if (_touchstoneLoginViewController) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.authenticationDelegate dismissViewControllerForTouchstoneController:self completion:^{
                _touchstoneLoginViewController = nil;
                self.loginRequestQueue.suspended = NO;
            }];
        }];
    }
    
    [self.lock unlock];
}

#pragma mark _Public
- (void)logout
{
    [self clearAllCredentials];
}

- (void)login:(void (^)(void))completed
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _login:completed];
    }];
}


#pragma mark _Delegates
#pragma mark MITTouchstoneAuthenticationDelegate
- (BOOL)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller canLoginWithCredential:(NSURLCredential*)credential
{
    return ([MITTouchstoneController identityProviderForCredential:credential] != nil);
}

- (void)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller didFinishWithCredential:(NSURLCredential*)credential
{
    [self.lock lock];
    
    self.credential = credential;

    // Our credentials have changed! This will force the controller
    // to enqueue another
    [self setNeedsToSendLoginRequest];
    [self enqueueLoginRequestIfNeeded];

    [self dismissLoginViewController];
    
    [self.lock unlock];
}

- (void)didCancelLoginViewController:(MITTouchstoneDefaultLoginViewController*)controller
{
    [self dismissLoginViewController];
}

@end
