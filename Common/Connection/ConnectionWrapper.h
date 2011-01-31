// Convenience wrapper for NSURLConnection's most common use case, asynchronous
// plain HTTP GET request of a URL string.
// 
// See Emergency Module for example usage.

#import <Foundation/Foundation.h>

@class ConnectionWrapper;

@protocol ConnectionWrapperDelegate <NSObject>

-(void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data;

@optional

-(void)connectionDidReceiveResponse:(ConnectionWrapper *)wrapper; // an opportunity to turn on the spinny, i.e. [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
-(void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error;
- (void)connection:(ConnectionWrapper *)wrapper madeProgress:(CGFloat)progress;

@end


@interface ConnectionWrapper : NSObject {
	NSMutableData *tempData;

    NSURL *theURL;
    NSURLConnection *urlConnection;
	BOOL isConnected;
    long long contentLength;
	
	id<ConnectionWrapperDelegate> delegate;
}

@property (nonatomic, retain) NSURL *theURL;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, assign, readonly) BOOL isConnected;
@property (nonatomic, assign) id<ConnectionWrapperDelegate> delegate;

- (id)initWithDelegate:(id<ConnectionWrapperDelegate>)theDelegate;
- (void)cancel;

- (void)resetObjects;

-(BOOL)requestDataFromURL:(NSURL *)url;
-(BOOL)requestDataFromURL:(NSURL *)url allowCachedResponse:(BOOL)shouldCache;

@end
