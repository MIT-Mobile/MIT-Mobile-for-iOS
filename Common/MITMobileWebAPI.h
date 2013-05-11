#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"
#import "MobileRequestOperation.h"

@compatibility_alias MITMobileWebAPI MobileRequestOperation;

@protocol JSONLoadedDelegate <NSObject>
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;

@optional
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;
- (void)request:(MITMobileWebAPI *)request totalBytesWritten:(NSInteger)bytesWritten totalBytesExpected:(NSInteger)bytesExpected;
- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request;
- (NSString *)request:(MITMobileWebAPI *)request displayHeaderForError: (NSError *)error;
- (id<UIAlertViewDelegate>)request:(MITMobileWebAPI *)request alertViewDelegateForError:(NSError *)error;
@end