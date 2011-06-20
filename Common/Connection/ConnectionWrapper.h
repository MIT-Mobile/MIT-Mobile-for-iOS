// Convenience wrapper for NSURLConnection's most common use case, asynchronous
// plain HTTP GET request of a URL string.
// 
// See Emergency Module for example usage.
#import <Foundation/Foundation.h>

@class ConnectionWrapper;

@protocol ConnectionWrapperDelegate <NSObject>

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data;

@optional

- (void)connectionDidReceiveResponse:(ConnectionWrapper *)wrapper; // an opportunity to turn on the spinny, i.e. [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
- (void)connectionWrapper:(ConnectionWrapper *)wrapper didReceiveResponse:(NSURLResponse*)response;
- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error;
- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress;
- (void)connectionWrapper:(ConnectionWrapper *)wrapper totalBytesWritten:(NSInteger)bytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpected;

@end


@interface ConnectionWrapper : NSObject {
	NSMutableData *_requestData;

    NSURL *_requestURL;
    NSURLRequest *_request;
    NSURLConnection *urlConnection;
	BOOL isConnected;
    long long contentLength;
	
	id<ConnectionWrapperDelegate> _delegate;
}

@property (nonatomic, retain) NSURL *theURL;
@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, assign) id<ConnectionWrapperDelegate> delegate;

- (id)initWithDelegate:(id<ConnectionWrapperDelegate>)theDelegate;
- (void)cancel;

- (void)resetObjects;

-(BOOL)requestDataWithRequest:(NSURLRequest*)url;
-(BOOL)requestDataFromURL:(NSURL *)url;
-(BOOL)requestDataFromURL:(NSURL *)url allowCachedResponse:(BOOL)shouldCache;

@end
