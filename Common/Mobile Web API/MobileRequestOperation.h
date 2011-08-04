#import <Foundation/Foundation.h>
#import "MobileRequestLoginViewController.h"

@class MobileRequestOperation;

typedef void (^MobileRequestProgressBlock)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger expectedBytesWritten);
typedef void (^MobileRequestCompleteBlock)(MobileRequestOperation *operation, id jsonResult, NSError *error);

@interface MobileRequestOperation : NSOperation <MobileRequestLoginViewDelegate> {
    NSString *_module;
    NSString *_command;
    NSString *_pathExtension;
    NSDictionary *_parameters;
    
    NSURLRequest *_activeRequest;
    NSURLConnection *_connection;
    NSMutableData *_requestData;
    
    BOOL _isExecuting;
    BOOL _usePOST;
}

@property (nonatomic,readonly,copy) NSString *module;
@property (nonatomic,readonly,copy) NSString *command;
@property (nonatomic,readonly,copy) NSString *pathExtension;
@property (nonatomic,readonly,copy) NSDictionary *parameters;
@property (nonatomic) BOOL usePOST;

@property (nonatomic,copy) MobileRequestCompleteBlock completeBlock;
@property (nonatomic,copy) MobileRequestProgressBlock progressBlock;

- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params;
- (NSURLRequest*)urlRequest;

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
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
