#import <Foundation/Foundation.h>
#import "MobileRequestLoginViewController.h"

@class MobileRequestOperation;

typedef void (^MobileRequestProgressBlock)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger expectedBytesWritten);
typedef void (^MobileRequestCompleteBlock)(MobileRequestOperation *operation, id jsonResult, NSError *error);

@interface MobileRequestOperation : NSOperation <MobileRequestLoginViewDelegate> {
    BOOL _isExecuting;
    BOOL _isFinished;
}

@property (nonatomic,readonly,copy) NSString *module;
@property (nonatomic,readonly,copy) NSString *command;
@property (nonatomic,readonly,copy) NSDictionary *parameters;
@property (nonatomic) BOOL usePOST;

+ (BOOL)isAuthenticationCookie:(NSHTTPCookie*)cookie;
+ (void)clearAuthenticatedSession;
+ (NSString*)userAgent;

/* 
 * Since these blocks may be used for UI operations
 *  they are guaranteed to be dispatched on the main
 *  queue in order to make life a bit simpler.
 * This also means that any long-running operations
 *  should either be dispatched onto a new queue/background
 *  thread to avoid blocking the main UI
 */
@property (nonatomic,copy) void (^completeBlock)(MobileRequestOperation *operation, id jsonResult, NSError *error);
@property (nonatomic,copy) void (^progressBlock)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger expectedBytesWritten);

+ (id)operationWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params;
- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params;
- (NSURLRequest*)urlRequest;

// Override the saved username/password (if there is one) when attempting
//  to authenticate to a Touchstone protected resource. Note that if the
//  username or password is incorrect (or authentication fails for any other
//  reason), the user will not be prompted to reenter their username and
//  password and the connection will return with an error.
- (void)authenticateUsingUsername:(NSString*)username password:(NSString*)password;

- (BOOL)isEqual:(NSObject*)object;
- (BOOL)isEqualToOperation:(MobileRequestOperation*)operation;
- (NSUInteger)hash;

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end
