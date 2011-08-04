#import "MobileRequestLoginViewController.h"
#import "MobileKeychainServices.h"

NSString* const MobileLoginKeychainIdentifier = @"edu.mit.mobile.MobileWebLogin";

enum {
    OKButtonTag = 0,
    CancelButtonTag
};

@interface MobileRequestLoginViewController ()
@property (nonatomic,retain) UIButton *loginButton;
@property (nonatomic,retain) UITextField *usernameField;
@property (nonatomic,retain) UITextField *passwordField;
@property (nonatomic,assign) BOOL shouldSaveLogin;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)toggleLoginSave:(id)sender;
@end

@implementation MobileRequestLoginViewController
@synthesize username,
            password,
            delegate,
            shouldSaveLogin,
            loginButton;

@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;

- (id)initWithIdentifier:(NSString*)identifier {
    NSDictionary *keychainItem = MobileKeychainFindItem(identifier, YES);
    
    return [self initWithUsername:[keychainItem objectForKey:kSecAttrAccount]
                         password:[keychainItem objectForKey:kSecValueData]];
}

- (id)initWithUsername:(NSString*)aUsername password:(NSString*)aPassword;
{
    self = [super init];
    if (self) {
        self.username = aUsername;
        self.password = aPassword;
    }
    
    return self;
}

- (void)dealloc {
    self.usernameField = nil;
    self.passwordField = nil;
    self.username = nil;
    self.password = nil;
    self.loginButton = nil;
    [super dealloc];
}

- (void)loadView {
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[UIView alloc] initWithFrame:mainFrame];
    
    mainView.backgroundColor = [UIColor colorWithRed:0.725
                                               green:0.776
                                                blue:0.839
                                               alpha:1.0];
    
    {
        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 41)] autorelease];
        titleLabel.text = @"Touchstone Login";
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.font = [UIFont systemFontOfSize:24.0];
        titleLabel.textAlignment = UITextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        [mainView addSubview:titleLabel];
    }
    
    {
        UILabel *infoLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 70, 280, 50)] autorelease];
        infoLabel.text = @"Please enter your Touchstone username and password below";
        infoLabel.textColor = [UIColor blackColor];
        infoLabel.textAlignment = UITextAlignmentLeft;
        infoLabel.font = [UIFont systemFontOfSize:14.0];
        infoLabel.lineBreakMode = UILineBreakModeWordWrap;
        infoLabel.numberOfLines = 2;
        infoLabel.backgroundColor = [UIColor clearColor];
        [mainView addSubview:infoLabel];
    }
    
    {
        CGRect userFrame = CGRectMake(50, 175, 220, 31);
        UITextField *userField = [[[UITextField alloc] initWithFrame:userFrame] autorelease];
        userField.placeholder = @"Username";
        userField.borderStyle = UITextBorderStyleRoundedRect;
        userField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        userField.autocorrectionType = UITextAutocorrectionTypeNo;
        userField.keyboardAppearance = UIKeyboardAppearanceDefault;
        userField.keyboardType = UIKeyboardTypeEmailAddress;
        userField.returnKeyType = UIReturnKeyNext;
        userField.delegate = self;
        
        if (self.username) {
            userField.text = self.username;
        }
        
        self.usernameField = userField;
        [mainView addSubview:userField];
    }
    
    {
        CGRect passFrame = CGRectMake(50, 215, 220, 31);
        
        UITextField *passField = [[[UITextField alloc] initWithFrame:passFrame] autorelease];
        passField.placeholder = @"Password";
        passField.secureTextEntry = YES;
        passField.borderStyle = UITextBorderStyleRoundedRect;
        passField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        passField.autocorrectionType = UITextAutocorrectionTypeNo;
        passField.keyboardAppearance = UIKeyboardAppearanceDefault;
        passField.returnKeyType = UIReturnKeyDone;
        passField.delegate = self;
        
        if (self.password) {
            passField.text = self.password;
        }
        
        self.passwordField = passField;
        [mainView addSubview:passField];
    }
    
    {
        CGRect saveFrame = CGRectMake(85, 292, 150, 21);
        UILabel *saveLabel = [[[UILabel alloc] initWithFrame:saveFrame] autorelease];
        saveLabel.textAlignment = UITextAlignmentCenter;
        saveLabel.text = @"Save your login?";
        saveLabel.backgroundColor = [UIColor clearColor];
        [mainView addSubview:saveLabel];
    }
    
    {
        CGRect switchFrame = CGRectMake(121, 321, 79, 27);
        UISwitch *checkButton = [[[UISwitch alloc] initWithFrame:switchFrame] autorelease];
        
        [checkButton addTarget:self
                        action:@selector(toggleLoginSave:)
              forControlEvents:UIControlEventValueChanged];
        
        [mainView addSubview:checkButton];
    }
    
    {
        CGRect cancelFrame = CGRectMake(20, 403, 98, 37);
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        cancelButton.frame = cancelFrame;
        cancelButton.tag = CancelButtonTag;
        
        [cancelButton setTitle:@"Cancel"
                      forState:UIControlStateNormal];
        [cancelButton addTarget:self
                         action:@selector(buttonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
        
        [mainView addSubview:cancelButton];
    }
    
    {
        CGRect okFrame = CGRectMake(202, 403, 98, 37);
        UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        submitButton.frame = okFrame;
        submitButton.tag = OKButtonTag;
        
        [submitButton setTitle:@"OK"
                      forState:UIControlStateNormal];
        [submitButton addTarget:self
                         action:@selector(buttonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
        submitButton.enabled = NO;
        
        self.loginButton = submitButton;
        [mainView addSubview:submitButton];
    }
    
    [self setView:[mainView autorelease]];
}

- (IBAction)buttonPressed:(id)sender {
    if (self.delegate) {
        switch ([sender tag]) {
            case OKButtonTag:
                [self.delegate loginRequest:self
                         didEndWithUsername:self.usernameField.text
                                   password:self.passwordField.text
                            shouldSaveLogin:self.shouldSaveLogin];
                break;
                
            case CancelButtonTag:
            default:
                [self.delegate cancelWasPressesForLoginRequest:self];
                break;
        }
    }
}

- (IBAction)toggleLoginSave:(id)sender {
    self.shouldSaveLogin = !self.shouldSaveLogin;
}

#pragma mark - UITextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.loginButton.enabled = ([self.usernameField.text length] > 0) && ([self.passwordField.text length] > 0);
    
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    } else if ([string isEqualToString:@"\t"]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.usernameField) {
        if ([self.passwordField.text length] == 0) {
            [self.usernameField resignFirstResponder];
            [self.passwordField becomeFirstResponder];
        }
    } else {
        [textField resignFirstResponder];
    }
}

@end
