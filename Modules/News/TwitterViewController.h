#import <UIKit/UIKit.h>
#import "XAuthTwitterEngine.h"

@interface UsernameFieldDelegate : NSObject <UITextFieldDelegate> {
	UITextField *passwordField;
}

- (id) initWithPasswordField: (UITextField *)passwordField;

@end

@class TwitterViewController;
@interface PasswordFieldDelegate : NSObject <UITextFieldDelegate> {
	TwitterViewController *delegate;
}

@property (nonatomic, assign) TwitterViewController *delegate;

@end

@interface MessageFieldDelegate : NSObject <UITextViewDelegate> {
	UILabel *counter;
}

- (id) initWithMessage: (NSString *)message counter: (UILabel *)aCounter;

@end

@interface TwitterViewController : UIViewController {
	NSString *message;
	NSString *longUrl;
	
	UIView *loginView;
	UIView *messageInputView;
	UILabel *usernameLabel;
	UIView *contentView;
	UINavigationItem *navigationItem;
	UIButton *signOutButton;
	
	UITextField *usernameField;
	UITextField *passwordField;
	
	UITextView *messageField;
	
	XAuthTwitterEngine *twitterEngine;
	BOOL authenticationRequestInProcess;
}

- (id) initWithMessage: (NSString *)aMessage url:(NSString *)longUrl;

@end
