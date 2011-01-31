#import <UIKit/UIKit.h>
#import "FBConnect.h"

@protocol ShareItemDelegate

- (NSString *)actionSheetTitle;

- (NSString *)emailSubject;
- (NSString *)emailBody;

- (NSString *)fbDialogPrompt;

// TODO: simplify the following...
// currently we are making the delegate do all the work of contstructing
// a JSON string to match the spec at
// http://wiki.developers.facebook.com/index.php/Attachment_%28Streams%29
- (NSString *)fbDialogAttachment;

- (NSString *)twitterUrl;
- (NSString *)twitterTitle;

@optional

@end


@interface ShareDetailViewController : UIViewController <UIActionSheetDelegate, FBSessionDelegate, FBDialogDelegate> {

	FBSession *fbSession;
	id<ShareItemDelegate> shareDelegate;

}

@property (nonatomic, retain) FBSession *fbSession;
@property (nonatomic, retain) id<ShareItemDelegate> shareDelegate;

- (void)share:(id)sender;
- (void)showTwitterView;
- (void)showFacebookDialog;
- (void)postItemToFacebook;

@end
