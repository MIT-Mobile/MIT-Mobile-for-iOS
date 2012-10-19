#import <UIKit/UIKit.h>

@protocol ShareItemDelegate <NSObject>

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
- (UIImage*)postImage;

@end


@interface ShareDetailViewController : UIViewController <UIActionSheetDelegate> {

}

@property (nonatomic, weak) id<ShareItemDelegate> shareDelegate;

- (void)share:(id)sender;
- (void)showFacebookDialog;
- (void)postItemToFacebook;

@end
