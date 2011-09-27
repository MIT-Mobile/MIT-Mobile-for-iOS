#import <UIKit/UIKit.h>

@interface SettingsTouchstoneViewController : UIViewController
@property (nonatomic, retain) UITextField *usernameField;
@property (nonatomic, retain) UITextField *passwordField;
@property (nonatomic, retain) UIButton *logoutButton;
@property (nonatomic, retain) UIButton *clearButton;

- (id)init;
@end
