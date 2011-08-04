#import <UIKit/UIKit.h>

extern NSString* const MobileLoginKeychainIdentifier;

@class MobileRequestLoginViewController;

@protocol MobileRequestLoginViewDelegate 
@required
- (void)loginRequest:(MobileRequestLoginViewController*)view
  didEndWithUsername:(NSString*)username
            password:(NSString*)password
     shouldSaveLogin:(BOOL)saveLogin;
- (void)cancelWasPressesForLoginRequest:(MobileRequestLoginViewController*)view;
@end

@interface MobileRequestLoginViewController : UIViewController <UITextFieldDelegate> {
    UITextField *_usernameField;
    UITextField *_passwordField;
    UISwitch *_saveLoginButton;
    UIButton *_submitButton;
}

@property (nonatomic,assign) id<MobileRequestLoginViewDelegate> delegate;

- (id)initWithIdentifier:(NSString*)identifier;
- (id)initWithUsername:(NSString*)user password:(NSString*)password;

@end
