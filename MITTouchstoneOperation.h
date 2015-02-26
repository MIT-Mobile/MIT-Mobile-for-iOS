#import <Foundation/Foundation.h>
#import "MITIdentityProvider.h"

extern NSString* const MITECPErrorDomain;

@protocol MITTouchstoneAuthenticationDelegate;
@class MITRequestOperation;
@class AFURLConnectionOperation;

@interface MITTouchstoneOperation : NSOperation
@property (nonatomic,readonly,strong) id<MITIdentityProvider> identityProvider;
@property (nonatomic,readonly,strong) NSURLCredential *credential;
@property (nonatomic,readonly,strong) NSError *error;
@property (readonly,getter=isSuccess) BOOL success;

@property (nonatomic,readonly,strong) NSHTTPURLResponse *response;
@property (nonatomic,readonly,copy) NSData *responseData;

- (instancetype)initWithRequestOperation:(AFURLConnectionOperation*)requestingOperation identityProvider:(id<MITIdentityProvider>)identityProvider credential:(NSURLCredential*)credential;

- (instancetype)initWithRequest:(NSURLRequest*)request identityProvider:(id<MITIdentityProvider>)identityProvider credential:(NSURLCredential*)credential;

@end
