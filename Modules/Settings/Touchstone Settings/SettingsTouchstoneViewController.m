#import <QuartzCore/QuartzCore.h>

#import "SettingsTouchstoneViewController.h"
#import "MITTouchstoneOperation.h"
#import "MITTouchstoneController.h"

#import "MITMobileServerConfiguration.h"
#import "ExplanatorySectionLabel.h"
#import "MITNavigationActivityView.h"
#import "MITAdditions.h"
#import "MITDeviceRegistration.h"

typedef NS_ENUM(NSInteger, MITTouchstoneSettingsViewTag) {
    MITTouchstoneSettingsViewUserTag = 0x49485400,
    MITTouchstoneSettingsViewPasswordTag,
    MITTouchstoneSettingsViewRememberMeTag,
    MITTouchstoneSettingsViewLogInTag
};

typedef NS_ENUM(NSInteger, MITTouchstoneSettingsSectionIndex) {
    MITTouchstoneSettingsCredentialsSectionIndex = 0,
    MITTouchstoneSettingsLogInSectionIndex,
    MITTouchstoneSettingsServerSettingsSectionIndex
};

static NSString* const MITTouchstoneSettingsLockIconExplanationText = @"A lock icon will appear next to services requiring authentication. Use your MIT Kerberos username or Touchstone Collaboration Account to log in.";

@interface SettingsTouchstoneViewController () <UITextFieldDelegate>
@property (nonatomic,weak) IBOutlet UITextField *usernameField;
@property (nonatomic,weak) IBOutlet UITextField *passwordField;
@property (nonatomic,weak) MITNavigationActivityView *activityView;

@property (nonatomic,readonly,strong) NSOperationQueue *authenticationOperationQueue;
@property (nonatomic,weak) NSOperation *currentOperation;

@property (nonatomic,getter=isAuthenticating) BOOL authenticating;
@property (nonatomic) BOOL needsToValidateCredentials;
@property BOOL advancedSettingsAreVisible;

- (void)setNeedsToValidateCredentials;
- (void)validateCredentialsIfNeeded;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)logInButtonPressed:(id)sender;
- (IBAction)didChangeCredentialPersistence:(id)sender;
@end

@implementation SettingsTouchstoneViewController
@synthesize authenticationOperationQueue = _authenticationOperationQueue;

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

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
        userField.tag = MITTouchstoneSettingsViewUserTag;
        
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
        passwordField.tag = MITTouchstoneSettingsViewPasswordTag;
        
        _passwordField = passwordField;
    }
    
    return passwordField;
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
    self.tableView.scrollEnabled = NO;
    self.title = @"Touchstone Settings";

    UISwipeGestureRecognizer *showGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(didRecognizeAdvancedSettingsGesture:)];
    showGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    showGesture.numberOfTouchesRequired = 2;
    [self.tableView addGestureRecognizer:showGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshNavigationBarItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.authenticationOperationQueue cancelAllOperations];
    [self cancelTouchstoneOperation];
}

#pragma mark IBAction Methods
- (IBAction)didRecognizeAdvancedSettingsGesture:(UISwipeGestureRecognizer*)swipeGesture
{
    if (swipeGesture.state == UIGestureRecognizerStateEnded) {
        if (self.advancedSettingsAreVisible) {
            swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
            self.advancedSettingsAreVisible = NO;
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:MITTouchstoneSettingsServerSettingsSectionIndex]
                          withRowAnimation:UITableViewRowAnimationRight];
        } else {
            swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
            self.advancedSettingsAreVisible = YES;
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:MITTouchstoneSettingsServerSettingsSectionIndex]
                          withRowAnimation:UITableViewRowAnimationRight];
        }
    }
}

- (IBAction)saveItemWasTapped:(UIBarButtonItem*)sender
{
    [self validateCredentialsIfNeeded];
}

- (IBAction)cancelItemWasTapped:(UIBarButtonItem*)sender
{
    [self cancelTouchstoneOperation];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneItemWasTapped:(UIBarButtonItem*)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSOperationQueue*)authenticationOperationQueue
{
    if (!_authenticationOperationQueue) {
        _authenticationOperationQueue = [[NSOperationQueue alloc] init];
        _authenticationOperationQueue.maxConcurrentOperationCount = 1;
        _authenticationOperationQueue.name = @"edu.mit.mobile.touchstone-settings.request";
    }

    return _authenticationOperationQueue;
}

- (void)reloadCredentialViews
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:MITTouchstoneSettingsCredentialsSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSURLCredential*)credential
{
    if (self.needsToValidateCredentials) {
        return [[NSURLCredential alloc] initWithUser:_usernameField.text
                                            password:_passwordField.text
                                         persistence:NSURLCredentialPersistencePermanent];
    } else {
        return [[MITTouchstoneController sharedController] storedCredential];
    }
}

- (void)refreshNavigationBarItems
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveItemWasTapped:)];
        
    if (self.needsToValidateCredentials) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)setNeedsToValidateCredentials
{
    self.needsToValidateCredentials = YES;
}

- (void)setNeedsToValidateCredentials:(BOOL)needsToValidateCredentials
{
    if (_needsToValidateCredentials != needsToValidateCredentials) {
        _needsToValidateCredentials = needsToValidateCredentials;
        [self refreshNavigationBarItems];
    }
}

- (void)validateCredentialsIfNeeded
{
    if (self.needsToValidateCredentials) {
        // Order is important for these next two lines.
        // The -credential method uses -needsToValidateCredentials
        // as a guard to see if it should spit back the currently saved credentials or
        // one formed from the contents of the user and password fields.
        NSURLCredential *credential = [self credential];
        self.needsToValidateCredentials = NO;

        [self setAuthenticating:YES animated:YES];
        
        [[MITTouchstoneController sharedController] loginWithCredential:credential
                                                             completion:^(BOOL success, NSError *error) {
                                                                 if (success) {
                                                                     [self didSuccessfullyAuthenticate];
                                                                 } else {
                                                                     [self didFailToAuthenticateWithError:error];
                                                                 }
                                                             }];
    }
}

- (void)setAuthenticating:(BOOL)authenticating
{
    [self setAuthenticating:authenticating animated:NO];
}

- (void)setAuthenticating:(BOOL)authenticating animated:(BOOL)animated;
{
    if (_authenticating != authenticating) {
        if (authenticating) {
            [self willBeginAuthenticating:animated];
        }
        
        _authenticating = authenticating;
        
        if (_authenticating) {
            [self didBeginAuthenticating:animated];
        } else {
            [self didEndAuthenticating:animated];
        }
    }
}

- (void)willBeginAuthenticating:(BOOL)animated
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    self.tableView.userInteractionEnabled = NO;
}

- (void)didBeginAuthenticating:(BOOL)animated
{
    self.navigationItem.titleView = self.activityView;
    [self.activityView startActivityWithTitle:@"Authenticating"];
}

- (void)didEndAuthenticating:(BOOL)animated
{
    self.tableView.userInteractionEnabled = YES;
    self.navigationItem.titleView = nil;
    [self.tableView reloadData];
}

- (void)didSuccessfullyAuthenticate
{
    [self setAuthenticating:NO animated:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Touchstone"
                                                        message:@"Credentials saved"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK",nil];
    [alertView show];
    [self refreshNavigationBarItems];
}

- (void)didFailToAuthenticateWithError:(NSError*)error
{
    [self setAuthenticating:NO animated:YES];
    
    UIAlertView *alertView = nil;
    if (error.code == NSURLErrorUserAuthenticationRequired) {
        alertView = [[UIAlertView alloc] initWithTitle:@"Touchstone"
                                               message:@"Invalid user or password"
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:@"OK",nil];
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:@"Touchstone"
                                               message:@"Unable to verify Touchstone credentials"
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:@"OK",nil];
    }
    
    alertView.delegate = self;
    [alertView show];
}

#pragma mark - Event Handlers
- (IBAction)cancelButtonPressed:(id)sender {
    [self.authenticationOperationQueue cancelAllOperations];
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
- (void)cancelTouchstoneOperation
{
    NSOperation *currentOperation = self.currentOperation;
    self.currentOperation = nil;
    [currentOperation cancel];
}


#pragma mark - UITextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    } else if ([string isEqualToString:@"\t"]) {
        return NO;
    }
    
    [self setNeedsToValidateCredentials];
    return YES;
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
        case MITTouchstoneSettingsCredentialsSectionIndex: {
            UIEdgeInsets textCellInsets = UIEdgeInsetsMake(0, 15, 0, 15);
            
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
                UITextField *textField = (UITextField*)[cell.contentView viewWithTag:MITTouchstoneSettingsViewUserTag];
                if (!textField) {
                    textField = self.usernameField;
                    textField.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds,textCellInsets);
                    [cell.contentView addSubview:textField];
                }
                
                if (!self.needsToValidateCredentials) {
                    textField.text = [self credential].user;
                }
            } else if ([identifier isEqualToString:@"TouchstoneLoginPasswordCell"]) {
                UITextField *textField = (UITextField*)[cell.contentView viewWithTag:MITTouchstoneSettingsViewPasswordTag];
                if (!textField) {
                    textField = self.passwordField;
                    textField.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds,textCellInsets);
                    [cell.contentView addSubview:textField];
                }
                
                if (!self.needsToValidateCredentials) {
                    textField.text = [self credential].password;
                }
            }
            
            return cell;
        }
            
        case MITTouchstoneSettingsLogInSectionIndex: {
            NSString *identifier = nil;
            if (indexPath.row == 0) {
                identifier = @"TouchstoneLoginLogOutCell";
            }
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }
            
            if ([identifier isEqualToString:@"TouchstoneLoginLogOutCell"]) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.text = @"Log Out of Touchstone";
                cell.textLabel.enabled = [[MITTouchstoneController sharedController] isLoggedIn];
                
                if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
                    cell.textLabel.textColor = [UIColor mit_tintColor];
                    cell.textLabel.textAlignment = NSTextAlignmentLeft;
                } else {
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                }
            }
            
            return cell;
        }

        case MITTouchstoneSettingsServerSettingsSectionIndex: {
            NSString *identifier = @"MITSettingsCellIdentifierAPIServer";

            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            }

            cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.65];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.backgroundColor = [UIColor clearColor];

            NSArray *servers = MITMobileWebGetAPIServerList();
            cell.textLabel.text = [servers[indexPath.row] host];

            NSURL *currentServer = MITMobileWebGetCurrentServerURL();
            cell.accessoryView = nil;

            if ([servers indexOfObject:currentServer] == indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

            return cell;
        }
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.advancedSettingsAreVisible) {
        return 3;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((MITTouchstoneSettingsSectionIndex)section) {
        case MITTouchstoneSettingsCredentialsSectionIndex:
            return 2;
        case MITTouchstoneSettingsLogInSectionIndex:
            return 1;
        case MITTouchstoneSettingsServerSettingsSectionIndex:
            return [MITMobileWebGetAPIServerList() count];
    }
    
    return 0;
}

#pragma mark - UITableView Delegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITTouchstoneSettingsLogInSectionIndex) {
        if (indexPath.row == 0) {
            return [[MITTouchstoneController sharedController] isLoggedIn];
        }
    } else if (indexPath.section == MITTouchstoneSettingsServerSettingsSectionIndex) {
        return YES;
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MITTouchstoneSettingsLogInSectionIndex) {
        if (indexPath.row == 0) {
            if ([[MITTouchstoneController sharedController] isLoggedIn]) {
                [[MITTouchstoneController sharedController] logout];
            
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                self.usernameField.text = nil;
                self.passwordField.text = nil;
                [tableView reloadData];

                [self refreshNavigationBarItems];
            }
        }
    } else if (indexPath.section == MITTouchstoneSettingsServerSettingsSectionIndex) {
        NSArray *serverURLs = MITMobileWebGetAPIServerList();
        NSURL *currentServerURL = MITMobileWebGetCurrentServerURL();
        NSURL *newServerURL = serverURLs[indexPath.row];

        NSUInteger indexOfCurrentURL = [serverURLs indexOfObject:currentServerURL];
        NSIndexPath *indexPathOfCurrentURL = [NSIndexPath indexPathForRow:indexOfCurrentURL inSection:MITTouchstoneSettingsServerSettingsSectionIndex];

        if ([serverURLs[indexPath.row] isEqual:MITMobileWebGetCurrentServerURL()]) {
            [tableView reloadRowsAtIndexPaths:@[indexPathOfCurrentURL] withRowAnimation:UITableViewRowAnimationNone];
            return;
        }

        MITMobileWebSetCurrentServerURL(serverURLs[indexPath.row]);

        NSUInteger indexOfNewURL = [serverURLs indexOfObject:newServerURL];
        NSIndexPath *indexPathOfNewURL = [NSIndexPath indexPathForRow:indexOfNewURL inSection:MITTouchstoneSettingsServerSettingsSectionIndex];
        [tableView reloadRowsAtIndexPaths:@[indexPathOfCurrentURL,indexPathOfNewURL] withRowAnimation:UITableViewRowAnimationNone];

        [MITDeviceRegistration clearIdentity];

        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
            [application registerForRemoteNotifications];
        } else {
            [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == MITTouchstoneSettingsLogInSectionIndex) {
        ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
        footerLabel.text = MITTouchstoneSettingsLockIconExplanationText;
        footerLabel.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
        return footerLabel;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == MITTouchstoneSettingsLogInSectionIndex) {
        CGFloat height = [ExplanatorySectionLabel heightWithText:MITTouchstoneSettingsLockIconExplanationText
                                                           width:CGRectGetWidth(tableView.bounds)
                                                            type:ExplanatorySectionFooter
                                                   accessoryView:[UIImageView accessoryViewWithMITType:MITAccessoryViewSecure]];
        return height + 8;
    }
    
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

@end
