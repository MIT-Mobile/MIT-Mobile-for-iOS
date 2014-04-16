#import <objc/runtime.h>

#import "MITTouchstoneController.h"
#import "MITTouchstoneIdentityProvider.h"
#import "MITTouchstoneNetworkIdentityProvider.h"
#import "MITTouchstoneDefaultLoginViewController.h"
#import "MITTouchstoneOperation.h"

#import "MITMobileServerConfiguration.h"
#import "MobileKeychainServices.h"

#pragma mark - Globals
static NSString* const MITTouchstoneLastLoggedInUserKey = @"MITTouchstoneLastLoggedInUser";
static NSString* const MITTouchstoneLoginViewControllerAssociatedObjectKey = @"MITTouchstoneLoginViewControllerAssociatedObject";
static NSString* const MITTouchstoneKeychainCredentialMigratedKey = @"MITMobileOperationKeychainCredentialMigrated";

#pragma mark - Static
static __weak MITTouchstoneController *_sharedTouchstonController = nil;


#pragma mark - Category Interfaces
@interface MITTouchstoneController () <MITTouchstoneLoginViewControllerDelegate>
@property (nonatomic,copy) NSDictionary *userInformation;

@property (weak) MITTouchstoneOperation *requestOperation;
@property (nonatomic,readonly,strong) NSOperationQueue *loginRequestQueue;
@property (nonatomic,readonly,strong) NSOperationQueue *loginCompletionQueue;

@property (strong) NSError *loginError;

@property (nonatomic,strong) NSURLCredential *storedCredential;


/* Migrates any saved credentials saved by MobileRequestOperation
 *  to the NSURLCredential store. By default, the credentials will be
 *  saved using the NSURLCredentialPersistencePermanent persistence type.
 *
 *  This was added in for version 3.5.2 and should be removed once we are sure
 *  no one is still upgrading from the pre-3.5.2 versions
 */
- (void)migrateCredentialsFromKeychain DEPRECATED_ATTRIBUTE;
- (BOOL)needsToPromptForCredential;
@end

#pragma mark - Main Implementation
@implementation MITTouchstoneController {
    __weak MITTouchstoneDefaultLoginViewController *_touchstoneLoginViewController;
}

@synthesize storedCredential = _storedCredential;
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
        [self migrateCredentialsFromKeychain];
    }
    
    return self;
}

- (void)migrateCredentialsFromKeychain
{
    id guard = [[NSUserDefaults standardUserDefaults] objectForKey:MITTouchstoneKeychainCredentialMigratedKey];
    if (!guard) {
        NSDictionary *savedCredential = MobileKeychainFindItem(MobileLoginKeychainIdentifier, YES);
        if (savedCredential) {
            DDLogInfo(@"migrating saved Touchstone credential for user %@", savedCredential[(__bridge id)kSecAttrAccount]);

            NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:savedCredential[(__bridge id)kSecAttrAccount]
                                                                       password:savedCredential[(__bridge id)kSecValueData]
                                                                    persistence:NSURLCredentialPersistencePermanent];
            self.storedCredential = credential;
            MobileKeychainDeleteItem(MobileLoginKeychainIdentifier);
        }

        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:MITTouchstoneKeychainCredentialMigratedKey];
    }
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

- (void)loadStoredCredential
{
    NSString *lastLoggedInUser = [[NSUserDefaults standardUserDefaults] stringForKey:MITTouchstoneLastLoggedInUserKey];
    NSURLCredentialStorage *sharedCredentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
    
    __block NSURLCredential *storedCredential = nil;
    __block NSURLCredential *fallbackCredential = nil;
    [[MITTouchstoneController allIdentityProviders] enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        NSDictionary *credentials = [sharedCredentialStorage credentialsForProtectionSpace:identityProvider.protectionSpace];
        
        if ([credentials count] > 1) {
            DDLogWarn(@"expected to find zero or one credetials, found %d",[credentials count]);
        }
        
        if (lastLoggedInUser && credentials[lastLoggedInUser]) {
            storedCredential = credentials[lastLoggedInUser];
            (*stop) = YES;
        } else if (!fallbackCredential) {
            if ([identityProvider canAuthenticateForUser:lastLoggedInUser]) {
                fallbackCredential = [NSURLCredential credentialWithUser:lastLoggedInUser password:nil persistence:NSURLCredentialPersistenceNone];
            }
        } else if ([credentials count] > 0) {
            DDLogWarn(@"found %d credentials but missing a value for %@",[credentials count],MITTouchstoneLastLoggedInUserKey);
        }
    }];
    
    if (storedCredential) {
        _storedCredential = storedCredential;
    } else if (fallbackCredential) {
        _storedCredential = fallbackCredential;
    } else {
        _storedCredential = nil;
    }
}

- (NSURLCredential*)storedCredential
{
    if (!_storedCredential) {
        [self loadStoredCredential];
    }

    return _storedCredential;
}

- (void)setStoredCredential:(NSURLCredential *)storedCredential
{
    if (![self.storedCredential isEqual:storedCredential]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

        NSURLCredential *existingCredential = self.storedCredential;
        if (existingCredential) {
            id<MITIdentityProvider> existingIdentityProvider = [MITTouchstoneController identityProviderForUser:existingCredential.user];
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:existingCredential forProtectionSpace:existingIdentityProvider.protectionSpace];
        }
        
        [standardUserDefaults removeObjectForKey:MITTouchstoneLastLoggedInUserKey];
        
        if (storedCredential && (storedCredential.persistence != NSURLCredentialPersistenceNone)) {
            id<MITIdentityProvider> identityProvider = [MITTouchstoneController identityProviderForUser:storedCredential.user];

            if (identityProvider) {
                [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:storedCredential forProtectionSpace:identityProvider.protectionSpace];
                [standardUserDefaults setObject:storedCredential.user forKey:MITTouchstoneLastLoggedInUserKey];
            } else {
                NSLog(@"No identity provider supports logging in with user %@",storedCredential.user);
            }
            
            _storedCredential = storedCredential;
        }
        
        [standardUserDefaults synchronize];
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

#pragma mark _Private
- (void)enqueueLoginCompletionBlock:(void (^)(BOOL success, NSError *error))completion
{
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

- (void)enqueueLoginRequestWithCredential:(NSURLCredential*)credential success:(void(^)(NSURLCredential *credential, NSDictionary *userInformation))success failure:(void(^)(NSError *error))failure
{
    // Cancel the pending operation and clear out the login request
    //  tracking ivar. This should stop the operation dead in its tracks
    //  if it hasn't completed yet and, if it has completed, then clearing out
    //  the loginRequestOperation ivar should prevent it from triggering
    //  the side-effects in the completion block (the locking is important here!)
    // Again, if there is no current request operation, this should be a NOP and
    //  not change any of the below behavior.
    NSOperation *currentRequestOperation = self.requestOperation;
    self.requestOperation = nil;
    [currentRequestOperation cancel];

    NSURLRequest *loginRequest = [[NSURLRequest alloc] initWithURL:[MITTouchstoneController loginEntryPointURL]
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:60.];

    MITTouchstoneOperation *operation = [[MITTouchstoneOperation alloc] initWithRequest:loginRequest
                                                                       identityProvider:[MITTouchstoneController identityProviderForUser:credential.user]
                                                                             credential:credential];
    self.requestOperation = operation;

    __weak MITTouchstoneController *weakSelf = self;
    __weak MITTouchstoneOperation *weakOperation = operation;
    operation.completionBlock = ^{
        MITTouchstoneController *blockSelf = weakSelf;
        MITTouchstoneOperation *blockOperation = weakOperation;

        if (blockSelf) {
            if (blockSelf.requestOperation == blockOperation) {
                if (blockOperation.isSuccess) {
                    NSError *error = nil;
                    NSDictionary *userInformation = [NSJSONSerialization JSONObjectWithData:blockOperation.responseData options:0 error:&error];

                    if (error) {
                        NSLog(@"failed to parse user information from request %@: %@",loginRequest,error);
                    }

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self loginDidSucceedWithCredential:credential userInformation:userInformation];

                        if (success) {
                            success(credential,userInformation);
                        }
                    }];

                } else {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self loginDidFailWithError:blockOperation.error];

                        if (failure) {
                            failure(blockOperation.error);
                        }
                    }];
                }

                blockSelf.requestOperation = nil;
            }
        }
    };

    [self.loginRequestQueue addOperation:operation];
}

- (void)loginDidSucceedWithCredential:(NSURLCredential*)credential userInformation:(NSDictionary*)userInformation
{
    NSLog(@"successful login as %@",credential.user);

    self.loginError = nil;
    self.storedCredential = credential;
}

- (void)loginDidFailWithError:(NSError*)error
{
    NSLog(@"login attempt failed");
    self.loginError = error;
}

- (BOOL)needsToPromptForCredential
{
    if (self.loginError) {
        return YES;
    } else {
        NSURLCredential *storedCredential = self.storedCredential;
        return !(storedCredential.user && [storedCredential hasPassword]);
    }
}

/** Sends a message to the authenticationDelegate to present
 *  a login view controller (if necessary) and suspends the
 *  internal operation queue.
 *
 *  This method needs to be balanced with a call to -dismissLoginViewController;
 * @return YES if a login view was presented
 */
- (BOOL)presentLoginViewControllerIfNeeded
{
    if (!_touchstoneLoginViewController && [self needsToPromptForCredential]) {
        MITTouchstoneDefaultLoginViewController *touchstoneViewController = [[MITTouchstoneDefaultLoginViewController alloc] initWithCredential:self.storedCredential];
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

        return YES;
    }

    return NO;
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
        }];
    }
}

#pragma mark _Public
- (BOOL)isLoggedIn
{

    NSArray *identityProviders = [MITTouchstoneController allIdentityProviders];
    NSMutableSet *idpHosts = [[NSMutableSet alloc] init];
    [identityProviders enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        [idpHosts addObject:identityProvider.URL.host];
    }];

    NSHTTPCookieStorage *sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    __block BOOL hasCookiesFromIdentityProvider = NO;
    [[sharedCookieStorage cookies] enumerateObjectsUsingBlock:^(NSHTTPCookie *cookie, NSUInteger idx, BOOL *stop) {
        if ([idpHosts containsObject:cookie.domain]) {
            hasCookiesFromIdentityProvider = YES;
            (*stop) = YES;
        }
    }];


    // These are ordered from least-expensive to most-expensive operation
    return (hasCookiesFromIdentityProvider ||
            self.userInformation ||
            self.storedCredential);
}

- (void)logout
{

    NSArray *identityProviders = [MITTouchstoneController allIdentityProviders];
    NSMutableSet *idpHosts = [[NSMutableSet alloc] init];
    [identityProviders enumerateObjectsUsingBlock:^(id<MITIdentityProvider> identityProvider, NSUInteger idx, BOOL *stop) {
        [idpHosts addObject:identityProvider.URL.host];
    }];

    NSHTTPCookieStorage *sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [[sharedCookieStorage cookies] enumerateObjectsUsingBlock:^(NSHTTPCookie *cookie, NSUInteger idx, BOOL *stop) {
        if ([idpHosts containsObject:cookie.domain]) {
            [sharedCookieStorage deleteCookie:cookie];
        } else if ([cookie.domain isEqualToString:MITMobileWebGetCurrentServerURL().host]) {
            [sharedCookieStorage deleteCookie:cookie];
        }
    }];

    self.userInformation = nil;
    self.storedCredential = nil;
    [self clearAllCredentials];
}

- (void)login:(void (^)(BOOL success, NSError *error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSURLCredential *credential = self.storedCredential;
        
        // Immediately suspend the queue for dispatching the completion blocks
        //  (login parameter). This will be resumed after a login completes (successfuly or not)
        //  completes and any waiting connections will be allowed to continue.
        // If this queue is already suspended, this will effectively be a NOP
        self.loginCompletionQueue.suspended = YES;
        
        if (credential) {
            [self enqueueLoginRequestWithCredential:credential success:^(NSURLCredential *credential, NSDictionary *userInformation) {
                self.loginCompletionQueue.suspended = NO;
            } failure:^(NSError *error) {
                [self presentLoginViewControllerIfNeeded];
            }];
        } else {
            [self presentLoginViewControllerIfNeeded];
        }
        
        [self enqueueLoginCompletionBlock:completion];
    }];
}

/**
 *  Attempt to login with the given credential.
 *  If the credential is nil or the credential is invalid
 *  the user will not be prompted to re-enter their credential
 *  and the login attempt will be considered a failure.
 *
 *  If the login attempt succeeds, the given credential will be saved according
 *  to the persistenceType.
 *
 *  This method is thread-safe and may be called from any queue.
 */
- (void)loginWithCredential:(NSURLCredential*)credential completion:(void(^)(BOOL success, NSError *error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // Immediately suspend the queue for dispatching the completion blocks
        //  (login parameter). This will be resumed after a login completes (successfuly or not)
        //  completes and any waiting connections will be allowed to continue.
        // If this queue is already suspended, this will effectively be a NOP
        self.loginCompletionQueue.suspended = YES;
        
        if (credential) {
            [self enqueueLoginRequestWithCredential:credential success:^(NSURLCredential *credential, NSDictionary *userInformation) {
                self.loginCompletionQueue.suspended = NO;
            } failure:^(NSError *error) {
                self.loginCompletionQueue.suspended = NO;
            }];
        } else {
            [self loginDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:nil]];
            self.loginCompletionQueue.suspended = NO;
        }
        
        [self enqueueLoginCompletionBlock:completion];
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
        [self enqueueLoginRequestWithCredential:credential success:^(NSURLCredential *credential, NSDictionary *userInformation) {
            self.loginCompletionQueue.suspended = NO;
        } failure:^(NSError *error) {
            // There are currently only a limited number of ways we can actually reach this point.
            self.loginCompletionQueue.suspended = NO;
        }];

        [self dismissLoginViewController];
    }];
}

- (void)didCancelLoginViewController:(MITTouchstoneDefaultLoginViewController*)controller
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self loginDidFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserCancelledAuthentication userInfo:nil]];
        [self dismissLoginViewController];

        self.loginCompletionQueue.suspended = NO;
    }];
}

@end
