#import <QuartzCore/QuartzCore.h>

#import "MITTouchstoneDefaultLoginViewController.h"
#import "MITTouchstoneOperation.h"
#import "MITTouchstoneController.h"

#import "ExplanatorySectionLabel.h"
#import "MITNavigationActivityView.h"

typedef NS_ENUM(NSInteger, MITTouchstoneLoginViewTag) {
    MITTouchstoneLoginViewUserTag = 0x49485400,
    MITTouchstoneLoginViewPasswordTag,
    MITTouchstoneLoginViewRememberMeTag,
    MITTouchstoneLoginViewLogInTag
};

typedef NS_ENUM(NSInteger, MITTouchstoneLoginSectionIndex) {
    MITTouchstoneLoginCredentialsSectionIndex = 0,
    MITTouchstoneLoginLogInSectionIndex,
    MITTouchstoneLoginRememberMeSectionIndex
};

@interface MITTouchstoneDefaultLoginViewController ()
@property (nonatomic,weak) IBOutlet UITextField *usernameField;
@property (nonatomic,weak) IBOutlet UITextField *passwordField;
@property (nonatomic,weak) IBOutlet UISwitch *persistCredentialsSwitch;
@property (nonatomic,weak) MITNavigationActivityView *activityView;

@property (nonatomic,weak) NSOperation *currentOperation;

@property (nonatomic,getter=isAuthenticating) BOOL authenticating;
@property (nonatomic,readonly) BOOL needsToValidateCredentials;

- (void)setNeedsToValidateCredentials;
- (void)validateCredentialsIfNeeded;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)logInButtonPressed:(id)sender;
- (IBAction)didChangeCredentialPersistence:(id)sender;
@end

@implementation MITTouchstoneDefaultLoginViewController {
    NSURLCredential *_credential;
}

- (instancetype)init
{
    return [self initWithCredential:nil];
}

- (instancetype)initWithCredential:(NSURLCredential*)credential
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _credential = credential;
    }
    
    return self;
}

#pragma mark - View Setup
- (UITextField*)usernameField
{
    UITextField *userField = _usernameField;
    if (!userField) {
        userField = [[UITextField alloc] init];
        userField.adjustsFontSizeToFitWidth = YES;
        userField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        userField.autocorrectionType = UITextAutocorrectionTypeNo;
        userField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);
        userField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        userField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        userField.delegate = self;
        userField.keyboardType = UIKeyboardTypeEmailAddress;
        userField.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
        userField.minimumFontSize = 10.0;
        userField.placeholder = @"Username or Email";
        userField.returnKeyType = UIReturnKeyNext;
        userField.textAlignment = NSTextAlignmentLeft;
        userField.text = self.credential.user;
        userField.tag = MITTouchstoneLoginViewUserTag;
        
        _usernameField = userField;
    }
    
    return userField;
}

- (UITextField*)passwordField
{
    UITextField *passwordField = _passwordField;
    
    if (!passwordField) {
        passwordField = [[UITextField alloc] init];
        passwordField.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                          UIViewAutoresizingFlexibleWidth);
        passwordField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passwordField.delegate = self;
        passwordField.placeholder = @"Password";
        passwordField.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
        passwordField.returnKeyType = UIReturnKeyDone;
        passwordField.secureTextEntry = YES;
        passwordField.text = self.credential.password;
        passwordField.tag = MITTouchstoneLoginViewPasswordTag;
        
        _passwordField = passwordField;
    }
    
    return passwordField;
}

- (UISwitch*)persistCredentialsSwitch
{
    UISwitch *persistCredentialsSwitch = _persistCredentialsSwitch;
    if (!persistCredentialsSwitch) {
        persistCredentialsSwitch = [[UISwitch alloc] init];
        persistCredentialsSwitch.tag = MITTouchstoneLoginViewRememberMeTag;
        [persistCredentialsSwitch addTarget:self
                                     action:@selector(didChangeCredentialPersistence:)
                           forControlEvents:UIControlEventValueChanged];
        
        _persistCredentialsSwitch = persistCredentialsSwitch;
    }
    
    return persistCredentialsSwitch;
}

- (MITNavigationActivityView*)activityView
{
    MITNavigationActivityView *activityView = _activityView;
    if (!activityView) {
        activityView = [[MITNavigationActivityView alloc] init];
        _activityView = activityView;
    }
    
    return activityView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.843
                                                     green:0.855
                                                      blue:0.878
                                                     alpha:1.0];
    
    self.title = @"Touchstone";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonPressed:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.authenticationOperationQueue = [[NSOperationQueue alloc] init];
    self.authenticationOperationQueue.maxConcurrentOperationCount = 1;
    
    //NSAssert(self.authenticationOperationQueue, @"an operation queue for performing authentication requests was not assigned");
    
    self.usernameField.text = _credential.user;
    self.passwordField.text = _credential.password;
    [self setNeedsToValidateCredentials];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSOperation *currentOperation = self.currentOperation;
    self.currentOperation = nil;
    [currentOperation cancel];
}

- (NSURLCredential*)credential
{
    if (!_credential) {
        _credential = [[NSURLCredential alloc] initWithUser:_usernameField.text
                                                   password:_passwordField.text
                                                persistence:NSURLCredentialPersistenceNone];
    }
    
    return _credential;
}

- (void)setNeedsToValidateCredentials
{
    _needsToValidateCredentials = YES;
    _credential = nil;
}

- (void)validateCredentialsIfNeeded
{
    if (self.needsToValidateCredentials) {
        _needsToValidateCredentials = NO;
        
        NSURLCredential *credential = self.credential;
        NSURLRequest *authRequest = [[NSURLRequest alloc] initWithURL:[MITTouchstoneController loginEntryPointURL]];
        id<MITIdentityProvider> identityProvider = [MITTouchstoneController identityProviderForCredential:credential];
        
        MITTouchstoneOperation *operation = [[MITTouchstoneOperation alloc] initWithRequest:authRequest
                                                                           identityProvider:identityProvider
                                                                                 credential:credential];
        BOOL animated = YES;
        
        __weak MITTouchstoneDefaultLoginViewController *weakSelf = self;
        __weak MITTouchstoneOperation *weakOperation = operation;
        operation.completionBlock = ^{
            MITTouchstoneDefaultLoginViewController *blockSelf = weakSelf;
            if (blockSelf) {
                MITTouchstoneOperation *blockOperation = weakOperation;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (blockSelf.currentOperation == blockOperation) {
                        blockSelf.currentOperation = nil;
                        
                        if (blockOperation.isSuccess) {
                            blockSelf->_credential = credential;
                        }
                        
                        [self didEndAuthenticating:animated didSucceed:blockOperation.isSuccess error:blockOperation.error];
                    }
                }];
            }
        };
     
        [self setAuthenticating:YES animated:animated];
        
        [self.currentOperation cancel];
        self.currentOperation = operation;
        [self.authenticationOperationQueue addOperation:operation];
    }
}

- (void)setAuthenticating:(BOOL)authenticating
{
    [self setAuthenticating:authenticating animated:NO];
}

- (void)setAuthenticating:(BOOL)authenticating animated:(BOOL)animated;
{
    if (_authenticating != authenticating) {
        NSURLCredential *credential = self.credential;
        if ([self.delegate loginViewController:self canLoginWithCredential:credential]) {
            if (authenticating) {
                [self willBeginAuthenticating:animated];
            }
            
            _authenticating = authenticating;
            
            if (_authenticating) {
                [self didBeginAuthenticating:animated];
            }
        }
    }
}

- (void)willBeginAuthenticating:(BOOL)animated
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)didBeginAuthenticating:(BOOL)animated
{
    self.navigationItem.titleView = self.activityView;
    [self.activityView startActivityWithTitle:@"Authenticating"];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITTouchstoneLoginLogInSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didEndAuthenticating:(BOOL)animated didSucceed:(BOOL)success error:(NSError*)error
{
    self.authenticating = NO;
    [self updateLogInButtonState];
    
    self.tableView.userInteractionEnabled = YES;
    self.navigationItem.titleView = nil;
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Touchstone"
                                                            message:[NSString stringWithFormat:@"%@",error]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK",nil];
        alertView.delegate = self;
        [alertView show];
    } else if (!success) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Touchstone"
                                                            message:@"Invalid user or password"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK",nil];
        alertView.delegate = self;
        [alertView show];
    } else {
        [self.delegate loginViewController:self didFinishWithCredential:self.credential];
    }
}

- (void)updateLogInButtonState
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITTouchstoneLoginLogInSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)isLogInButtonEnabled
{
    NSURLCredential *credential = self.credential;
    BOOL canLoginWithCredential = [self.delegate loginViewController:self canLoginWithCredential:credential];
    
    return ([_usernameField.text length] &&
            [_passwordField.text length] &&
            canLoginWithCredential &&
            [self needsToValidateCredentials]);
}

#pragma mark - Event Handlers
- (IBAction)cancelButtonPressed:(id)sender {
    [self.authenticationOperationQueue cancelAllOperations];
    [self.delegate didCancelLoginViewController:self];
}

- (IBAction)logInButtonPressed:(id)sender
{
    [self validateCredentialsIfNeeded];
}

- (IBAction)didChangeCredentialPersistence:(id)sender
{
    // Nothing to do here...
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Private Methods



#pragma mark - UITextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    } else if ([string isEqualToString:@"\t"]) {
        return NO;
    }
    
    [self setNeedsToValidateCredentials];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self updateLogInButtonState];
    }];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateLogInButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.usernameField]) {
        [[self.view nextResponder] becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return NO;
}

#pragma mark - UIAlertView Delegate

#pragma mark - UITableView Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITTouchstoneLoginCredentialsSectionIndex: {
            UIEdgeInsets textCellInsets = UIEdgeInsetsMake(0, 15, 0, 15);
            if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
                textCellInsets = UIEdgeInsetsMake(5, 10, 5, 10);
            }
            
            NSString *identifier = nil;
            if (indexPath.row == 0) {
                identifier = @"TouchstoneLoginUserCell";
            } else if (indexPath.row == 1) {
                identifier = @"TouchstoneLoginPasswordCell";
            }
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            
            if ([identifier isEqualToString:@"TouchstoneLoginUserCell"]) {
                UITextField *textField = (UITextField*)[cell.contentView viewWithTag:MITTouchstoneLoginViewUserTag];
                if (!textField) {
                    textField = self.usernameField;
                    textField.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds,textCellInsets);
                    [cell.contentView addSubview:textField];
                }
                
                textField.text = _credential.user;
            } else if ([identifier isEqualToString:@"TouchstoneLoginPasswordCell"]) {
                UITextField *textField = (UITextField*)[cell.contentView viewWithTag:MITTouchstoneLoginViewPasswordTag];
                if (!textField) {
                    textField = self.passwordField;
                    textField.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds,textCellInsets);
                    [cell.contentView addSubview:textField];
                }
                
                textField.text = _credential.password;
            }
            
            return cell;
        }
            
        case MITTouchstoneLoginLogInSectionIndex: {
            NSString *identifier = nil;
            if (indexPath.row == 0) {
                identifier = @"TouchstoneLoginLogInCell";
            }
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            
            if ([identifier isEqualToString:@"TouchstoneLoginLogInCell"]) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text = @"Log In";
                
                if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                    cell.textLabel.textColor = [UIColor colorWithRed:0.639
                                                                     green:0.112
                                                                      blue:0.204
                                                                     alpha:1.];
                    cell.textLabel.textAlignment = NSTextAlignmentLeft;
                } else {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                }
                
                cell.selectionStyle = ([self isLogInButtonEnabled] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
                cell.textLabel.enabled = [self isLogInButtonEnabled];
            }
            
            return cell;
        }
            
        case MITTouchstoneLoginRememberMeSectionIndex: {
            NSString *identifier = nil;
            if (indexPath.row == 0) {
                identifier = @"TouchstoneLoginRememberMeCell";
            }
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            
            if ([identifier isEqualToString:@"TouchstoneLoginRememberMeCell"]) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryView = self.persistCredentialsSwitch;
                cell.textLabel.text = @"Remember Login";
            }
            
            return cell;
        }
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((MITTouchstoneLoginSectionIndex)section) {
        case MITTouchstoneLoginCredentialsSectionIndex:
            return 2;
        case MITTouchstoneLoginLogInSectionIndex:
            return 1;
        case MITTouchstoneLoginRememberMeSectionIndex:
            return 1;
    }
    
    return 0;
}

#pragma mark - UITableView Delegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITTouchstoneLoginLogInSectionIndex) {
        return (indexPath.row == 0) && [self isLogInButtonEnabled];
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MITTouchstoneLoginLogInSectionIndex) {
        if ((indexPath.row == 0) && [self isLogInButtonEnabled]) {
            [self setNeedsToValidateCredentials];
            [self validateCredentialsIfNeeded];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == MITTouchstoneLoginLogInSectionIndex) {
        NSString *labelText = @"Log in with your MIT Kerberos username or Touchstone Collaboration Account to continue.";
        ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
        footerLabel.text = labelText;
        return footerLabel;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // section 1 == log in button
    if (section == 1) {
        NSString *labelText = @"Log in with your MIT Kerberos username or Touchstone Collaboration Account to continue.";
        CGFloat height = [ExplanatorySectionLabel heightWithText:labelText 
                                                           width:self.view.frame.size.width
                                                            type:ExplanatorySectionFooter];
        return height;
    }
    return 0;
}

@end
