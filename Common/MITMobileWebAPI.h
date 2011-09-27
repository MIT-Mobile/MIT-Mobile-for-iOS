#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class MITMobileWebAPI;

@protocol JSONLoadedDelegate <NSObject>
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;

@optional
- (void)request:(MITMobileWebAPI *)request totalBytesWritten:(NSInteger)bytesWritten totalBytesExpected:(NSInteger)bytesExpected;
- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request;
- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error;
- (id<UIAlertViewDelegate>)request:(MITMobileWebAPI *)request alertViewDelegateForError:(NSError *)error;
@end


@interface MITMobileWebAPI : NSObject <ConnectionWrapperDelegate> {
	id<JSONLoadedDelegate> _jsonDelegate;
    ConnectionWrapper *_connectionWrapper;
    BOOL _usePOSTMethod;
	NSMutableDictionary *_params;
    NSString *_pathExtension;
	id _userData;
}

@property (nonatomic, retain) id<JSONLoadedDelegate> jsonDelegate;
@property (nonatomic) BOOL usePOSTMethod;
@property (nonatomic, readonly, retain) ConnectionWrapper *connectionWrapper;
@property (nonatomic, readonly, copy) NSDictionary *params; // make it easy for creator to identify requests
@property (nonatomic, readonly, copy) NSString *pathExtension;
@property (nonatomic, retain) id userData; // allow creator to add additional information to request

+ (MITMobileWebAPI *) jsonLoadedDelegate: (id<JSONLoadedDelegate>)delegate;
+ (NSURL *) buildURL:(NSDictionary *)dict queryBase:(NSString *)base;
+ (NSString *)buildQuery:(NSDictionary *)dict;
+ (void)showErrorWithHeader:(NSString *)header;
+ (void)showError:(NSError *)error header:(NSString *)header alertViewDelegate:(id<UIAlertViewDelegate>)alertViewDelegate;

- (id)initWithModule:(NSString *)module
             command:(NSString*)command
          parameters:(NSDictionary*)params;
- (id)initWithJSONLoadedDelegate: (id<JSONLoadedDelegate>)delegate;

- (BOOL)requestObjectFromModule:(NSString *)moduleName
                        command:(NSString *)command
                     parameters:(NSDictionary *)parameters
                      usingPOST:(BOOL)post;
- (BOOL)requestObjectFromModule:(NSString *)moduleName
                        command:(NSString *)command
                     parameters:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters;
- (BOOL)requestObject:(NSDictionary *)parameters pathExtension:(NSString *)extendedPath;

- (BOOL)start;
- (BOOL)isActive;
- (void)abortRequest;
- (void)cancel;
- (NSURL*)requestURL;
- (BOOL)setValue:(NSString*)value forParameter:(NSString*)param;

@end
