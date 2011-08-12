#import <QuartzCore/QuartzCore.h>

#import "MobileRequestLoginViewController.h"
#import "MobileKeychainServices.h"

@interface MobileRequestLoginViewController ()
@property (nonatomic,retain) UIButton *loginButton;
@property (nonatomic,retain) UITextField *usernameField;
@property (nonatomic,retain) UITextField *passwordField;
@property (nonatomic,retain) UILabel *errorLabel;
@property (nonatomic,assign) BOOL shouldSaveLogin;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
@property (nonatomic,retain) UIView *activityView;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)toggleLoginSave:(id)sender;
@end

@implementation MobileRequestLoginViewController
@synthesize activityView = _activityView,
            delegate = _delegate,
            errorLabel = _errorLabel,
            loginButton = _loginButton,
            passwordField = _passwordField,
            shouldSaveLogin = _shouldSaveLogin,
            usernameField = _usernameField,
            username = _username,
            password = _password;

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
        CGRect navBarFrame = CGRectMake(0, 0, 320, 44);
        UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:navBarFrame] autorelease];
        UINavigationItem *navItem = [[[UINavigationItem alloc] initWithTitle:@"Login"] autorelease];
        UIBarButtonItem *cancelItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                     target:self
                                                                                     action:@selector(cancelButtonPressed:)] autorelease];
        [navItem setLeftBarButtonItem:cancelItem];
        [navBar setItems:[NSArray arrayWithObject:navItem]];
        
        [mainView addSubview:navBar];
    }
    
    {
        UILabel *infoLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 44, 280, 50)] autorelease];
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
        UILabel *errorLabel = [[[UILabel alloc] initWithFrame:CGRectMake(50, 102, 220, 40)] autorelease];
        errorLabel.hidden = NO;
        errorLabel.numberOfLines = 2;
        errorLabel.lineBreakMode = UILineBreakModeWordWrap;
        errorLabel.textAlignment = UITextAlignmentCenter;
        errorLabel.textColor = [UIColor redColor];
        errorLabel.backgroundColor = [UIColor clearColor];
        
        self.errorLabel = errorLabel;
        [mainView addSubview:self.errorLabel];
    }
    
    {
        CGRect userFrame = CGRectMake(50, 150, 220, 31);
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
        CGRect passFrame = CGRectMake(50, 189, 220, 31);
        
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
        CGRect saveFrame = CGRectMake(85, 228, 150, 21);
        UILabel *saveLabel = [[[UILabel alloc] initWithFrame:saveFrame] autorelease];
        saveLabel.textAlignment = UITextAlignmentCenter;
        saveLabel.text = @"Save your login?";
        saveLabel.backgroundColor = [UIColor clearColor];
        [mainView addSubview:saveLabel];
    }
    
    {
        CGRect switchFrame = CGRectMake(121, 257, 79, 27);
        UISwitch *checkButton = [[[UISwitch alloc] initWithFrame:switchFrame] autorelease];
        
        [checkButton addTarget:self
                        action:@selector(toggleLoginSave:)
              forControlEvents:UIControlEventValueChanged];
        
        [mainView addSubview:checkButton];
    }
    
    {
        CGRect okFrame = CGRectMake(85,382,150,37);
        UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        submitButton.frame = okFrame;
        
        [submitButton setTitle:@"Submit"
                      forState:UIControlStateNormal];
        [submitButton addTarget:self
                         action:@selector(loginButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
        submitButton.enabled = NO;
        
        self.loginButton = submitButton;
        [mainView addSubview:submitButton];
    }
    
    {
        UIView *promptView = [[[UIView alloc] initWithFrame:CGRectMake(64, 164, 190, 132)] autorelease];
        promptView.backgroundColor = [UIColor colorWithWhite:0.0
                                                       alpha:0.85];
        promptView.layer.borderColor = [[UIColor whiteColor] CGColor];
        promptView.layer.borderWidth = 2.0;
        promptView.layer.cornerRadius = 5.0;
        
        {
            UILabel *infoLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 20, 150, 47)] autorelease];
            infoLabel.text = @"Logging into Touchstone";
            infoLabel.numberOfLines = 2;
            infoLabel.lineBreakMode = UILineBreakModeWordWrap;
            infoLabel.backgroundColor = [UIColor clearColor];
            infoLabel.textAlignment = UITextAlignmentCenter;
            infoLabel.textColor = [UIColor whiteColor];
            [promptView addSubview:infoLabel];
        }
        
        {
            UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
            activityView.frame = CGRectMake(77, 75, 37, 37);
            activityView.hidesWhenStopped = NO;
            [activityView startAnimating];
            [promptView addSubview:activityView];
        }
        
        self.activityView = promptView;
    }
    
    [self setView:[mainView autorelease]];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self showError:nil];
    if (self.delegate) {
        [self.delegate cancelWasPressedForLoginRequest:self];
    }
}

- (IBAction)loginButtonPressed:(id)sender {
    [self showError:nil];
    
    if (self.delegate) {
        [self.delegate loginRequest:self
                 didEndWithUsername:self.usernameField.text
                           password:self.passwordField.text
                    shouldSaveLogin:self.shouldSaveLogin];
    }
}

- (IBAction)toggleLoginSave:(id)sender {
    self.shouldSaveLogin = !self.shouldSaveLogin;
}

- (void)showError:(NSString*)error {
    if (error == nil) {
        self.errorLabel.text = @"";
    } else {
        self.errorLabel.text = error;
    }
}

- (void)showActivityView {
    [self.view addSubview:self.activityView];
}

- (void)hideActivityView {
    [self.activityView removeFromSuperview];
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
            [self.passwordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
}

@end
