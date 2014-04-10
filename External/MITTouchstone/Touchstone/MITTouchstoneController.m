#import <objc/runtime.h>

#import "MITTouchstoneController.h"
#import "MITTouchstoneIdentityProvider.h"
#import "MITTouchstoneNetworkIdentityProvider.h"
#import "MITTouchstoneDefaultLoginViewController.h"
#import "MITTouchstoneOperation.h"

#import "MITMobileServerConfiguration.h"

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

@property (strong) NSError *loginError;

@property (nonatomic,strong) NSURLCredential *savedCredential;

- (BOOL)needsToPromptForCredential;
@end

#pragma mark - Main Implementation
@implementation MITTouchstoneController {
    BOOL _needsToSendLoginRequest;
    __weak MITTouchstoneDefaultLoginViewController *_touchstoneLoginViewController;
    __weak MITTouchstoneOperation *_loginRequestOperation;
}

@synthesize savedCredential = _savedCredential;
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

+ (id<MITIdentityProvider>)identityProviderForUser:(NSString*)user
{
    if (!user) {
        return nil;
    }
    
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
    NSURL *currentServerURL = MITMobileWebGetCurrentServerURL();
    return [NSURL URLWithString:@"/api/?module=libraries&command=getUserIdentity"
                  relativeToURL:currentServerURL];
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
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MITTouchstoneLastLoggedInUserKey];
}

- (BOOL)hasSavedCredential
{
    return (self.savedCredential != nil);
}

- (void)loadSavedCredential
{
    NSString *lastLoggedInUser = [[NSUserDefaults standardUserDefaults] stringForKey:MITTouchstoneLastLoggedInUserKey];
    NSURLCredentialStorage *sharedCredentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
    
    __block NSURLCredential *savedCredential = nil;
    [[MITTouchstoneController allIdentityProviders] enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        NSDictionary *credentials = [sharedCredentialStorage credentialsForProtectionSpace:identityProvider.protectionSpace];
        
        if ([credentials count] > 1) {
            NSAssert([credentials count], @"expected to find zero or one credetials, found %d",[credentials count]);
        }
        
        if (lastLoggedInUser && credentials[lastLoggedInUser]) {
            savedCredential = credentials[lastLoggedInUser];
            (*stop) = YES;
        } else if ([identityProvider canAuthenticateForUser:lastLoggedInUser]) {
            savedCredential = [NSURLCredential credentialWithUser:lastLoggedInUser password:nil persistence:NSURLCredentialPersistenceNone];
            (*stop) = YES;
        } else if ([credentials count] > 0) {
            NSLog(@"found %d credentials but missing a value for %@",[credentials count],MITTouchstoneLastLoggedInUserKey);
        }
    }];
    
    _savedCredential = savedCredential;
}

- (NSURLCredential*)savedCredential
{
    if (!_savedCredential) {
        [self loadSavedCredential];
    }

    return _savedCredential;
}

- (void)setSavedCredential:(NSURLCredential *)savedCredential
{
    if (![self.savedCredential isEqual:savedCredential]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        
        if ([self hasSavedCredential]) {
            NSURLCredential *existingCredential = self.savedCredential;
            NSAssert(_savedCredential, @"hasSavedCredential returned YES but no saved credential found");
            
            id<MITIdentityProvider> existingIdentityProvider = [MITTouchstoneController identityProviderForUser:existingCredential.user];
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:existingCredential forProtectionSpace:existingIdentityProvider.protectionSpace];
        }
        
        [standardUserDefaults removeObjectForKey:MITTouchstoneLastLoggedInUserKey];
        
        if (savedCredential && (savedCredential.persistence != NSURLCredentialPersistenceNone)) {
            id<MITIdentityProvider> identityProvider = [MITTouchstoneController identityProviderForUser:savedCredential.user];
            if (identityProvider) {

                [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:savedCredential forProtectionSpace:identityProvider.protectionSpace];
                
                [standardUserDefaults setObject:savedCredential.user forKey:MITTouchstoneLastLoggedInUserKey];
            } else {
                NSLog(@"No identity provider supports logging in with user %@",savedCredential.user);
            }
        }
        
        [standardUserDefaults synchronize];
        _savedCredential = nil;
    }
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

#pragma mark _Privateq
- (void)_login:(void (^)(BOOL success, NSError *error))completion
{
    [self presentLoginViewControllerIfNeeded];
    [self enqueueLoginRequestWithCredential:self.savedCredential];

    // Declared early on since this is used in both the operations below
    __weak MITTouchstoneController *weakSelf = self;
    if (completion) {
        [self.loginCompletionQueue addOperationWithBlock:^{
            MITTouchstoneController *blockSelf = weakSelf;
            if (blockSelf) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (!blockSelf.loginError) {
                        completion(YES,nil);
                    } else {
                        completion(NO,blockSelf.loginError);
                    }
                }];
            } else {
                NSLog(@"Touchstone controller was prematurely deallocated; be prepared for unforseen consequences.");

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completion(NO,nil);
                }];
            }
        }];
    }
}

- (void)setNeedsToSendLoginRequest
{
    _needsToSendLoginRequest = YES;
}

- (BOOL)needsToSendLoginRequest
{
    return !_loginRequestOperation || _needsToSendLoginRequest;
}

- (void)enqueueLoginRequestWithCredential:(NSURLCredential*)credential
{
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

    MITTouchstoneOperation *operation = [[MITTouchstoneOperation alloc] initWithRequest:loginRequest
                                                                       identityProvider:[MITTouchstoneController identityProviderForUser:credential.user]
                                                                             credential:credential];
    _loginRequestOperation = operation;

    __weak MITTouchstoneController *weakSelf = self;
    __weak MITTouchstoneOperation *weakOperation = operation;
    operation.completionBlock = ^{
        MITTouchstoneController *blockSelf = weakSelf;
        MITTouchstoneOperation *blockOperation = weakOperation;

        // Assume last
        if (blockSelf) {
            if (blockSelf->_loginRequestOperation == blockOperation) {
                if (blockOperation.isSuccess) {
                    NSError *error = nil;
                    NSDictionary *userInformation = [NSJSONSerialization JSONObjectWithData:blockOperation.responseData options:0 error:&error];

                    if (error) {
                        NSLog(@"failed to parse user information from request %@: %@",loginRequest,error);
                    }

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [blockSelf loginDidSucceedWithCredential:credential userInformation:userInformation];
                    }];

                } else {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [blockSelf loginDidFailWithError:blockOperation.error];
                    }];
                }

                _loginRequestOperation = nil;
            }
        }
    };

    [self.loginRequestQueue addOperation:operation];
}

- (void)loginDidSucceedWithCredential:(NSURLCredential*)credential userInformation:(NSDictionary*)userInformation
{
    NSLog(@"successful login as %@",credential.user);

    self.loginError = nil;
    self.savedCredential = credential;

    self.loginCompletionQueue.suspended = NO;
}

- (void)loginDidFailWithError:(NSError*)error
{
    NSLog(@"login attempt failed");
    self.loginError = error;

    self.loginCompletionQueue.suspended = NO;
}

- (BOOL)needsToPromptForCredential
{
    if (self.loginError) {
        return YES;
    } else if (![self hasSavedCredential]) {
        return YES;
    } else {
        NSURLCredential *savedCredential = self.savedCredential;
        return !(savedCredential.user && [savedCredential hasPassword]);
    }
}

/** Sends a message to the authenticationDelegate to present
 *  a login view controller (if necessary) and suspends the
 *  internal operation queue.
 *
 *  This method needs to be balanced with a call to -dismissLoginViewController;
 */
- (void)presentLoginViewControllerIfNeeded
{
    if (!_touchstoneLoginViewController && [self needsToPromptForCredential]) {
        self.loginRequestQueue.suspended = YES;
        
        MITTouchstoneDefaultLoginViewController *touchstoneViewController = [[MITTouchstoneDefaultLoginViewController alloc] initWithCredential:self.savedCredential];
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
}

/** Sends a message to the authenticationDelegate that it should dismiss the
 *  presented login view controller (if one is currently active) and resumes
 *  the internal operation queue.
 */
- (void)dismissLoginViewController
{
    if (_touchstoneLoginViewController) {
        [self.authenticationDelegate dismissViewControllerForTouchstoneController:self completion:^{
            _touchstoneLoginViewController = nil;
            self.loginRequestQueue.suspended = NO;
        }];
    }
}

#pragma mark _Public
- (void)logout
{
    [self clearAllCredentials];
}

- (void)login:(void (^)(BOOL success, NSError *error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _login:completion];
    }];
}


#pragma mark _Delegates
#pragma mark MITTouchstoneAuthenticationDelegate
- (BOOL)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller canLoginForUser:(NSString*)user
{
    return ([MITTouchstoneController identityProviderForUser:user] != nil);
}

- (void)loginViewController:(MITTouchstoneDefaultLoginViewController*)controller didFinishWithCredential:(NSURLCredential*)credential
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setNeedsToSendLoginRequest];
        [self enqueueLoginRequestWithCredential:credential];
        [self dismissLoginViewController];
    }];
}

- (void)didCancelLoginViewController:(MITTouchstoneDefaultLoginViewController*)controller
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self dismissLoginViewController];
    }];
}

@end
