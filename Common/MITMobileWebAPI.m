
#import "MITMobileWebAPI.h"
#import "MITMobileServerConfiguration.h"
#import "MIT_MobileAppDelegate.h"
#import "MITJSON.h"

#define TIMED_OUT_CODE -1001
#define JSON_ERROR_CODE -2

@implementation MITMobileWebAPI

@synthesize jsonDelegate, connectionWrapper, params, userData;

- (id) initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	if((self = [super init])) {
		jsonDelegate = [delegate retain];
        connectionWrapper = nil;
		userData = nil;
	}
	return self;
}

+ (MITMobileWebAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	return [[[self alloc] initWithJSONLoadedDelegate:delegate] autorelease];
}

- (void) dealloc
{
	connectionWrapper.delegate = nil;
    [connectionWrapper release];
	[jsonDelegate release];
    jsonDelegate = nil;
	self.userData = nil;
	self.params = nil;
	[super dealloc];
}

-(void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	id result = [MITJSON objectWithJSONData:data];
	if(result) {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[jsonDelegate request:self jsonLoaded:result];
        self.connectionWrapper = nil;
		[self release];	
	} else {
		NSError *error = [NSError errorWithDomain:@"MITMobileWebAPI" code:JSON_ERROR_CODE 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"failed to handle JSON data", @"message", data, @"data", nil]];
		[self connection:wrapper handleConnectionFailureWithError:error];
	}
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError: (NSError *)error {
	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
	
    self.connectionWrapper = nil;
	//NSLog(@"connection failed in %@, userinfo: %@, url: %@", [error domain], [error userInfo], wrapper.theURL);
    
	if([jsonDelegate respondsToSelector:@selector(handleConnectionFailureForRequest:)]) {
		[jsonDelegate handleConnectionFailureForRequest:self];
	}
	
	if([jsonDelegate request:self shouldDisplayStandardAlertForError:error]) {
		NSString *header;
		if ([jsonDelegate respondsToSelector:@selector(request:displayHeaderForError:)]) {
			header = [jsonDelegate request:self displayHeaderForError:error];
		} else {
			header = @"Network Error";
		}
		
		id<UIAlertViewDelegate> alertViewDelegate = nil;
		if ([jsonDelegate respondsToSelector:@selector(request:alertViewDelegateForError:)]) {
			alertViewDelegate = [jsonDelegate request:self alertViewDelegateForError:error];
		} 
		
		[MITMobileWebAPI showError:error header:header alertViewDelegate:alertViewDelegate];
	}

	[self release];
}

+ (void)showErrorWithHeader:(NSString *)header {
	[self showError:nil header:header alertViewDelegate:nil];
}

+ (void)showError:(NSError *)error header:(NSString *)header alertViewDelegate:(id<UIAlertViewDelegate>)alertViewDelegate {
	
	// Generic message
	NSString *message = @"Connection Failure. Please try again later.";
	// if the error can be classifed we will use a more specific error message
	if(error) {
		if ([[error domain] isEqualToString:@"NSURLErrorDomain"] && ([error code] == TIMED_OUT_CODE)) {
			message = @"Connection Timed Out. Please try again later.";
		} else if ([[error domain] isEqualToString:@"MITMobileWebAPI"] && ([error code] == JSON_ERROR_CODE)) {
			message = @"Server Failure. Please try again later.";
		}
	}

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:header 
														message:message
													   delegate:alertViewDelegate 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	
	[alertView show];
	[alertView release];
}
	
- (void)abortRequest {
	if (connectionWrapper != nil) {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[connectionWrapper cancel];
		self.connectionWrapper = nil;
	}
	[self release];
}

- (BOOL) requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters {
	
	NSMutableDictionary *allParameters;
	if(parameters != nil) {
		allParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	} else {
		allParameters = [NSMutableDictionary dictionary];
	}
	
    if (moduleName) {
        [allParameters setObject:moduleName	forKey:@"module"];
    }
    if (command) {
        [allParameters setObject:command forKey:@"command"];
    }
	
	return [self requestObject:allParameters];
}
	
- (BOOL)requestObject:(NSDictionary *)parameters {
	return [self requestObject:parameters pathExtension:nil];
}

- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath {
	[self retain]; // retain self until connection completes;
	self.params = parameters;
	
	NSString *path;
    NSString *url = [MITMobileWebGetCurrentServerURL() absoluteString];
	if(extendedPath) {
		path = [url stringByAppendingFormat:@"/%@",extendedPath];
	} else {
        if ([url hasSuffix:@"/"])
            path = url;
        else
            path = [url stringByAppendingString:@"/"];
	}
	
	NSAssert(!self.connectionWrapper, @"The connection wrapper is already in use");
	
    // TODO: see if this needs and autorelease
	self.connectionWrapper = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
	BOOL requestSuccessfullyBegun = [connectionWrapper requestDataFromURL:[MITMobileWebAPI buildURL:self.params queryBase:path]];
	
	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) showNetworkActivityIndicator];
	
	if(!requestSuccessfullyBegun) {
		[self connection:self.connectionWrapper handleConnectionFailureWithError:nil];
	}
	return requestSuccessfullyBegun;
}

+ (NSString *)buildQuery:(NSDictionary *)dict {
	NSArray *keys = [dict allKeys];
	NSMutableArray *components = [NSMutableArray arrayWithCapacity:[keys count]];
	for (NSString *key in keys) {
		NSString *value = [[dict objectForKey:key] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
	}
	return [components componentsJoinedByString:@"&"];
}

// internal method used to construct URL
+(NSURL *)buildURL:(NSDictionary *)dict queryBase:(NSString *)base {
	NSString *urlString = [NSString stringWithFormat:@"%@?%@", base, [MITMobileWebAPI buildQuery:dict]];	
	NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return url;
}

@end
