
#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class MITMobileWebAPI;

@protocol JSONLoadedDelegate <NSObject>
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;

@optional 
- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request;
@end


@interface MITMobileWebAPI : NSObject <ConnectionWrapperDelegate> {
	id<JSONLoadedDelegate> jsonDelegate;
    ConnectionWrapper *connectionWrapper;
}

- (id) initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

+ (MITMobileWebAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

- (void)abortRequest;
- (BOOL)requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath;
+ (NSURL *) buildQuery:(NSDictionary *)dict queryBase:(NSString *)base;

@property (nonatomic, assign) id<JSONLoadedDelegate> jsonDelegate;
@property (nonatomic, retain) ConnectionWrapper *connectionWrapper;

@end
