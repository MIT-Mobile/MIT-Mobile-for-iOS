#import "ConnectionWrapper.h"

#define TIMEOUT_INTERVAL	15.0


@implementation ConnectionWrapper

@synthesize delegate, isConnected, urlConnection, theURL;

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
		tempData = nil;
		self.urlConnection = nil;
		[self resetObjects];
	}
	
	return self;
}

- (void)dealloc {
    self.delegate = nil;
    [urlConnection release];
	[tempData release];
    [theURL release];
	[super dealloc];
}

- (void)resetObjects {
	isConnected = false;
	[tempData release];
    tempData = nil;
}

- (void)cancel {
    if (isConnected) {
        [urlConnection cancel];
        self.urlConnection = nil;
        [self resetObjects];
    }
}

#pragma mark -
#pragma mark NSURLConnection delegation
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[tempData setLength:0];	// could receive multiple responses (e.g. from redirect), so reset tempData with every request (last request received will deliver payload)
    contentLength = [response expectedContentLength];
    if ([delegate respondsToSelector:@selector(connectionDidReceiveResponse:)]) {
        [delegate connectionDidReceiveResponse:self];	// have the delegate decide what to do with the error
    }    
}

// internal method used by NSURLConnection
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {	// should be repeatedly called until download is complete. this method will only be called after there are no more responses received (see above method)
	[tempData appendData:data];		// got some data in, so append it
    
    if ([delegate respondsToSelector:@selector(connection:madeProgress:)]) {
        NSUInteger lengthComplete = [tempData length];
        CGFloat progress;
        if (contentLength != NSURLResponseUnknownLength) {
            progress = (CGFloat)lengthComplete / (CGFloat)contentLength;
        } else {
            // at least let the delegate know we got something
            progress = 0.5;
        }
        [delegate connection:self madeProgress:progress];
    }
}

// internal method used by NSURLConnection
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {	// download's done, so do something with the data
    if (connection == self.urlConnection) {
        isConnected = false;
        [delegate connection:self handleData:tempData];
        self.urlConnection = nil; // release the NSURLConnection object
    }
}

// internal method used by NSURLConnection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {	// download failed for some reason, so handle it
    if (connection == self.urlConnection) {
        if ([delegate respondsToSelector:@selector(connection:handleConnectionFailureWithError:)]) {
            [delegate connection:self handleConnectionFailureWithError:error];	// have the delegate decide what to do with the error
        }
        isConnected = false;
        self.urlConnection = nil; // release the connection object
    }
}

#pragma mark Request methods

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

	NSURLRequest *request = [NSURLRequest requestWithURL:	url
											 cachePolicy:	cachePolicy	// Make sure not to cache in case of update for URL
										 timeoutInterval:	TIMEOUT_INTERVAL];
	
	// 'pre-flight' check to make sure it will go through
	if(![NSURLConnection canHandleRequest:request]) {	// if the request will fail
		[self resetObjects];							// then release & reset variables
		return NO;										// and notify of failure
	}
	
	self.urlConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];	// try and form a connection
	
	if (self.urlConnection) {			// if the connection was successfully formed
		isConnected = YES;								// record that it's successful
		tempData = [ [NSMutableData data] retain ];		// then allocate memory for incoming data
		return YES;									// and notify of success
	}
	
	// otherwise, connection was not successfully formed
	[self resetObjects];		// so reset & release temp objects
	return NO;				// and notify of failure
}

@end
