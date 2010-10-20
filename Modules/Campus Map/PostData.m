
#import "PostData.h"
#import "MIT_MobileAppDelegate.h"
#define kDefaultRequestTimeout 20

@implementation PostData
@synthesize delegate		= _delegate;
@synthesize requestTimeout	= _requestTimeout;
@synthesize receivedData	= _receivedData;
@synthesize api				= _api;
@synthesize useNetworkActivityIndicator = _useNetworkActivityIndicator;
@synthesize userData = _userData;

-(id) init
{
	self = [super init];
	
	_requestTimeout = kDefaultRequestTimeout;
	
	self.useNetworkActivityIndicator = NO;
	
	return self;
}

-(id) initWithDelegate:(id<PostDataDelegate>) delegate
{
	self = [self init];
	self.delegate = delegate;
	return self;
}

-(void) dealloc
{
	self.api = nil;
	self.delegate = nil;
	self.receivedData = nil;
	self.userData = nil;
	
	[super dealloc];
}

-(void) postDataInDictionary:(NSDictionary*) params toURL:(NSURL*) url
{
	NSMutableString *str = [[NSMutableString alloc] init];
	
	if (params) 
	{
		
		int i;
		NSArray *names = [params allKeys];
		for (i = 0; i < [names count]; i++) {
			if (i == 0) {
				 //[str appendString:@"?"];
			} else if (i > 0) {
				[str appendString:@"&"];
			}
			NSString *name = [names objectAtIndex:i];
			NSString* strToAdd = [params objectForKey:name ];
			
			//strToAdd = [strToAdd stringByReplacingOccurrencesOfString:@" " withString:@"+"];
			//strToAdd = [strToAdd stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString* nonAlphaNumValidChars = @"!*'();:@&=+$,/?%#[]";
			CFStringRef encodedStringToAdd = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																					 (CFStringRef)strToAdd,
																					 NULL,
																					 (CFStringRef)nonAlphaNumValidChars,
																					 kCFStringEncodingUTF8);
			strToAdd = [NSString stringWithString:(NSString*)encodedStringToAdd];
			
			strToAdd = [strToAdd stringByReplacingOccurrencesOfString:@" " withString:@"+"];
			
			[str appendString:[NSString stringWithFormat:@"%@=%@", name, strToAdd]];
			CFRelease(encodedStringToAdd);
			
		}
	}
	
	// Construct an NSMutableURLRequest for the URL and set appropriate request method.
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
															  cachePolicy:NSURLRequestReloadIgnoringCacheData 
														  timeoutInterval:_requestTimeout];
	
	[theRequest setHTTPMethod:@"POST"];    
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
	
	[theRequest setValue:[NSString stringWithFormat:@"%d", data.length] forHTTPHeaderField:@"Content-Length"];
	
	[theRequest setHTTPBody:data];
	
	[str release];
	
	NSURLConnection* theConnection = nil;
	theConnection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	
	if(nil == theConnection)
	{
		// inform the user that the download could not be made
		if(nil != _delegate && [_delegate respondsToSelector:@selector(postData:error:)])
		{
			[_delegate postData:self error:@"ConnectionError"];
		}
		
	}
	else 
	{
		if(self.useNetworkActivityIndicator) {
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate showNetworkActivityIndicator];
        }
		
	}


	
}

-(void) getDataFromURL:(NSURL*)url
{
	
	// create the request
	NSMutableURLRequest *theRequest = [NSMutableURLRequest  requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
										 timeoutInterval:_requestTimeout];
	
	[theRequest setHTTPMethod:@"GET"];  
	NSURLConnection* theConnection = nil;
	theConnection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	
	if(nil == theConnection)
	{
		// inform the user that the download could not be made
		if(nil != _delegate && [_delegate respondsToSelector:@selector(postData:error:)])
		{
			[_delegate postData:self error:@"ConnectionError"];
		}
		
	}
	else 
	{
		if(self.useNetworkActivityIndicator) {
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate showNetworkActivityIndicator];
        }
		
	}
	
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// reset the data object. 
	self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	self.receivedData = nil;
	
	if(self.useNetworkActivityIndicator) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate hideNetworkActivityIndicator];
    }
	
	// inform the user that the download could not be made
	if(nil != _delegate && [_delegate respondsToSelector:@selector(postData:error:)])
	{
		[_delegate postData:self error:@"ConnectionError"];
	}
	
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(self.useNetworkActivityIndicator) {
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate hideNetworkActivityIndicator];
    }

	// inform the user that the download could not be made
	if(nil != _delegate && [_delegate respondsToSelector:@selector(postData:receivedData:)])
	{
		[_delegate postData:self receivedData:self.receivedData];
	}
}



@end
