#import "ConnectionWrapper.h"
#import "MobileRequestOperation.h"

#define TIMEOUT_INTERVAL	15.0

@interface ConnectionWrapper ()
@property (nonatomic,retain) NSMutableData *requestData;
@end

@implementation ConnectionWrapper

@synthesize delegate = _delegate;
@synthesize isConnected;
@synthesize urlConnection;
@synthesize theURL = _requestUrl;
@synthesize request = _request;
@synthesize requestData = _requestData;

// designated initializer
- (id)initWithDelegate:(id<ConnectionWrapperDelegate>)theDelegate {
    self = [self init];
    self.delegate = theDelegate;
    return self;
}

- (id)init {
	self = [super init];

	if (self != nil) {
		isConnected = false;
        self.requestData = nil;
		self.urlConnection = nil;
		[self resetObjects];
	}
	
	return self;
}

- (void)dealloc {
    self.delegate = nil;
    self.theURL = nil;
    self.request = nil;
    self.requestData = nil;
    self.urlConnection = nil;
	[super dealloc];
}

- (void)resetObjects {
    self.requestData = nil;
    self.urlConnection = nil;
    self.request = nil;
	isConnected = false;
}

- (void)cancel {
    if (isConnected) {
        [urlConnection cancel];
        [self resetObjects];
    }
}

#pragma mark - NSURLConnection delegation
- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    NSMutableURLRequest *newRequest = [request mutableCopy];
    
    if (redirectResponse != nil) {
        // Go ahead and allow the redirect (for now)
        [newRequest setURL:[redirectResponse URL]];
    }
    
    return [newRequest autorelease];
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if ([self.delegate respondsToSelector:@selector(connectionWrapper:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [self.delegate connectionWrapper:self
                       totalBytesWritten:totalBytesWritten
               totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // Handle the case where the class may receive multiple connection:didReciveResponse:
    // messages. Apple's docs state that should multiple messages be received,
    // all previous data should be ignored:
    // http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSURLConnection_Class/Reference/Reference.html
    if (self.requestData) {
        [self.requestData setLength:0];
    }
    
    contentLength = [response expectedContentLength];
    if ([self.delegate respondsToSelector:@selector(connectionDidReceiveResponse:)]) {
        [self.delegate connectionDidReceiveResponse:self];	// have the delegate decide what to do with the error
    } else if ([self.delegate respondsToSelector:@selector(connectionWrapper:didReceiveResponse:)]) {
        [self.delegate connectionWrapper:self didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {	// should be repeatedly called until download is complete. this method will only be called after there are no more responses received (see above method)
	if (self.requestData == nil) {
        self.requestData = [NSMutableData data];
    }
    
    [self.requestData appendData:data];
    
    if ([self.delegate respondsToSelector:@selector(connection:madeProgress:)]) {
        NSUInteger lengthComplete = [self.requestData length];
        CGFloat progress;
        
        if (contentLength != NSURLResponseUnknownLength) {
            progress = (CGFloat)lengthComplete / (CGFloat)contentLength;
        } else {
            progress = NSURLResponseUnknownLength;
        }
        
        [self.delegate connection:self madeProgress:progress];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {	// download's done, so do something with the data
    if (connection == self.urlConnection) {
        [self.delegate connection:self
                       handleData:[NSData dataWithData:self.requestData]];
        
        isConnected = false;
        self.requestData = nil;
        self.urlConnection = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {	// download failed for some reason, so handle it
    if (connection == self.urlConnection) {
        if ([self.delegate respondsToSelector:@selector(connection:handleConnectionFailureWithError:)]) {
            [self.delegate connection:self handleConnectionFailureWithError:error];	// have the delegate decide what to do with the error
        }
        
        isConnected = false;
        self.requestData = nil;
        self.urlConnection = nil; // release the connection object
    }
}

#pragma mark Request methods
- (BOOL)requestDataWithRequest:(NSURLRequest*)request {
    NSMutableURLRequest *newRequest = [[request mutableCopy] autorelease];
    [newRequest setValue:[MobileRequestOperation userAgent]
      forHTTPHeaderField:@"User-Agent"];
    
    // 'pre-flight' check to make sure it will go through
	if(![NSURLConnection canHandleRequest:newRequest]) {	// if the request will fail
		[self resetObjects];							// then release & reset variables
		return NO;										// and notify of failure
	}
	
	self.urlConnection = [[[NSURLConnection alloc] initWithRequest:newRequest
                                                          delegate:self] autorelease];	// try and form a connection
	
	if (self.urlConnection) {			// if the connection was successfully formed
		isConnected = YES;								// record that it's successful
		return YES;									// and notify of success
	}
	
	// otherwise, connection was not successfully formed
	[self resetObjects];		// so reset & release temp objects
	return NO;				// and notify of failure
}

-(BOOL)requestDataFromURL:(NSURL *)url {
    return [self requestDataFromURL:url allowCachedResponse:NO];
}

-(BOOL)requestDataFromURL:(NSURL *)url allowCachedResponse:(BOOL)shouldCache {
	if (isConnected) {	// if there's already a connection established
		return NO;		// notify of failure
	}
	
    VLog(@"Requesting URL %@ %@", url, ((shouldCache) ? @"allowing cached responses" : @"ignoring cache"));
    
	// prep the variables for incoming data
	[self resetObjects];
	
    self.theURL = url;
    
	// create the request
    NSURLRequestCachePolicy cachePolicy = (shouldCache) ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

	NSURLRequest *request = [NSURLRequest requestWithURL: url
											 cachePolicy: cachePolicy	// Make sure not to cache in case of update for URL
										 timeoutInterval: TIMEOUT_INTERVAL];
	
	return [self requestDataWithRequest:request];
}

@end
