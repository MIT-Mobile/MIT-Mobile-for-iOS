
#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class MITMobileWebAPI;

@protocol JSONLoadedDelegate <NSObject>
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;

@optional 
- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request;

- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error;

- (id<UIAlertViewDelegate>)request:(MITMobileWebAPI *)request alertViewDelegateForError:(NSError *)error;
@end


@interface MITMobileWebAPI : NSObject <ConnectionWrapperDelegate> {
	id<JSONLoadedDelegate> jsonDelegate;
    ConnectionWrapper *connectionWrapper;
	NSDictionary *params;
	id userData;
    NSURL *_requestURL;
}

- (id) initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

+ (MITMobileWebAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

- (void)abortRequest;
- (BOOL)requestObjectFromModule:(NSString *)moduleName command:(NSString *)command parameters:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters pathExtension: (NSString *)extendedPath;
+ (NSURL *) buildURL:(NSDictionary *)dict queryBase:(NSString *)base;
+ (NSString *)buildQuery:(NSDictionary *)dict;
+ (void)showErrorWithHeader:(NSString *)header;
+ (void)showError:(NSError *)error header:(NSString *)header alertViewDelegate:(id<UIAlertViewDelegate>)alertViewDelegate;

@property (nonatomic, assign) id<JSONLoadedDelegate> jsonDelegate;
@property (nonatomic, retain) ConnectionWrapper *connectionWrapper;
@property (nonatomic, retain) NSDictionary *params; // make it easy for creator to identify requests
@property (nonatomic, retain) id userData; // allow creator to add additional information to request

@end
