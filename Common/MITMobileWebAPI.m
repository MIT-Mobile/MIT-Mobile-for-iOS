
#import "MITMobileWebAPI.h"
#import "MITMobileServerConfiguration.h"
#import "MIT_MobileAppDelegate.h"
#import "MITJSON.h"

#define TIMED_OUT_CODE -1001
#define JSON_ERROR_CODE -2

@interface MITMobileWebAPI ()
@property (nonatomic, retain) ConnectionWrapper *connectionWrapper;
@property (nonatomic, retain) NSDictionary *params; // make it easy for creator to identify requests
@property (nonatomic, copy) NSString *pathExtension;
@end

@implementation MITMobileWebAPI

@synthesize jsonDelegate = _jsonDelegate;
@synthesize connectionWrapper = _connectionWrapper;
@synthesize params = _params;
@synthesize pathExtension = _pathExtension;
@synthesize userData = _userData;

- (id)initWithModule:(NSString *)module command:(NSString*)command parameters:(NSDictionary*)params {
    self = [self initWithJSONLoadedDelegate:nil];
    
    if (self) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
        
        [dict setObject:module
                 forKey:@"module"];
        [dict setObject:command
                 forKey:@"command"];
        self.params = dict;
        self.jsonDelegate = nil;
    }
    
    return self;
}

- (id)initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	if((self = [super init])) {
		self.jsonDelegate = delegate;
        self.connectionWrapper = nil;
        self.pathExtension = nil;
		self.userData = nil;
        self.pathExtension = nil;
	}
	return self;
}

+ (MITMobileWebAPI *)jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate {
	return [[[self alloc] initWithJSONLoadedDelegate:delegate] autorelease];
}

- (void)dealloc
{
	self.connectionWrapper.delegate = nil;
    self.connectionWrapper = nil;
	self.jsonDelegate = nil;
    self.userData = nil;
    self.params = nil;
    self.pathExtension = nil;
	[super dealloc];
}

-(void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	id result = [MITJSON objectWithJSONData:data];
	if(result) {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[self.jsonDelegate request:self jsonLoaded:result];
        self.connectionWrapper = nil;
		[self release];	
	} else {
		NSError *error = [NSError errorWithDomain:@"MITMobileWebAPI" code:JSON_ERROR_CODE 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"failed to handle JSON data", @"message", data, @"data", nil]];
		[self connection:wrapper handleConnectionFailureWithError:error];
	}
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError: (NSError *)error {
    id<JSONLoadedDelegate> delegate = self.jsonDelegate;
    
	[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
	
	VLog(@"connection failed in %@, userinfo: %@, url: %@", [error domain], [error userInfo], wrapper.theURL);
    
	if([delegate respondsToSelector:@selector(handleConnectionFailureForRequest:)]) {
		[delegate handleConnectionFailureForRequest:self];
	}
	
	if([delegate request:self shouldDisplayStandardAlertForError:error]) {
		NSString *header;
		if ([delegate respondsToSelector:@selector(request:displayHeaderForError:)]) {
			header = [delegate request:self displayHeaderForError:error];
		} else {
			header = @"Network Error";
		}
		
		id<UIAlertViewDelegate> alertViewDelegate = nil;
		if ([delegate respondsToSelector:@selector(request:alertViewDelegateForError:)]) {
			alertViewDelegate = [delegate request:self alertViewDelegateForError:error];
		} 
		
		[MITMobileWebAPI showError:error header:header alertViewDelegate:alertViewDelegate];
	}
    
    self.connectionWrapper = nil;
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
	if (self.connectionWrapper) {
		[((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]) hideNetworkActivityIndicator];
		[self.connectionWrapper cancel];
	}
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
	self.pathExtension = extendedPath;
    
	NSAssert(!self.connectionWrapper, @"The connection wrapper is already in use");
	
    // TODO: see if this needs and autorelease
	self.connectionWrapper = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
	BOOL requestSuccessfullyBegun = [self.connectionWrapper requestDataFromURL:[self requestURL]];
	
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
		[components addObject:[NSString stringWithFormat:@"%@=%@", key, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	return [components componentsJoinedByString:@"&"];
}

// internal method used to construct URL
+(NSURL *)buildURL:(NSDictionary *)dict queryBase:(NSString *)base {
	NSString *urlString = [NSString stringWithFormat:@"%@?%@", base, [MITMobileWebAPI buildQuery:dict]];
	NSURL *url = [NSURL URLWithString:urlString];
	return url;
}

- (NSString*)description {
    return [[self requestURL] absoluteString];
}

- (NSUInteger)hash {
    return [[self description] hash];
}


- (BOOL)start {
    return [self requestObject:self.params pathExtension:nil];
}

// Wrapper method for -abortRequest
- (void)cancel {
    if (self.connectionWrapper) {
        [self abortRequest];
    }
}

- (NSURL*)requestURL {
    NSString *requestBase = [MITMobileWebGetCurrentServerURL() absoluteString];
    
    if ([requestBase hasSuffix:@"/"] == NO) {
        requestBase = [requestBase stringByAppendingString:@"/"];
    }
    
    if (self.pathExtension) {
        requestBase = [requestBase stringByAppendingFormat:@"%@/",self.pathExtension];
    }
    
    NSURL *reqURL = [MITMobileWebAPI buildURL:self.params
                                    queryBase:requestBase];
    return reqURL;
}

- (BOOL)isActive {
    return (self.connectionWrapper != nil);
}

@end
