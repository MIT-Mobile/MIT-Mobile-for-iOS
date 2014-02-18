#import <QuartzCore/QuartzCore.h>

#import "MobileRequestLoginViewController.h"
#import "MobileKeychainServices.h"
#import "ExplanatorySectionLabel.h"
#import "MITNavigationActivityView.h"
#import "UIKit+MITAdditions.h"

@interface MobileRequestLoginViewController ()
@property (nonatomic,retain) NSDictionary *tableCells;

@property (nonatomic,assign) UITextField *usernameField;
@property (nonatomic,assign) UITextField *passwordField;
@property (nonatomic,assign) UISwitch *saveCredentials;
@property (nonatomic,assign) UITableViewCell *logInCell;

@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
@property (nonatomic,retain) MITNavigationActivityView *activityView;

@property (nonatomic) BOOL dismissAfterAlert;

@property (nonatomic,readonly) BOOL shouldSaveLogin;
@property (nonatomic) BOOL showActivityView;

- (void)setupTableCells;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)logInButtonPressed:(id)sender;
@end

@implementation MobileRequestLoginViewController
#pragma mark -

@dynamic shouldSaveLogin;
@dynamic showActivityView;
#pragma mark -

- (id)initWithIdentifier:(NSString*)identifier {
    NSDictionary *keychainItem = MobileKeychainFindItem(identifier, YES);
    
    return [self initWithUsername:[keychainItem objectForKey:(id)kSecAttrAccount]
                         password:[keychainItem objectForKey:(id)kSecValueData]];
}

- (id)initWithUsername:(NSString*)aUsername password:(NSString*)aPassword;
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.username = aUsername;
        self.password = aPassword;
    }
    
    return self;
}

- (void)dealloc {
    self.username = nil;
    self.password = nil;
    self.tableCells = nil;
    self.activityView = nil;
    [super dealloc];
}

#pragma mark - View Setup
- (void)setupTableCells
{
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    UIEdgeInsets textCellInsets = UIEdgeInsetsMake(0, 15, 0, 15);
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        textCellInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    }
    CGRect fieldFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.rowHeight), textCellInsets);
    
    {
        UITableViewCell *usernameCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITextField *userField = [[[UITextField alloc] init] autorelease];
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
        
        if ([self.username length]) {
            userField.text = self.username;
        }
        
        userField.frame = fieldFrame;
        
        self.usernameField = userField;
        [usernameCell.contentView addSubview:userField];
        [cells setObject:usernameCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    {
        UITextField *passField = [[[UITextField alloc] init] autorelease];
        passField.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleWidth);
        passField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        passField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passField.delegate = self;
        passField.placeholder = @"Password";
        passField.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
        passField.returnKeyType = UIReturnKeyDone;
        passField.secureTextEntry = YES;
        
        if ([self.password length]) {
            passField.text = self.password;
        }
        
        passField.frame = fieldFrame;
        
        self.passwordField = passField;
        
        UITableViewCell *passwordCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [passwordCell.contentView addSubview:passField];
        
        [cells setObject:passwordCell
                  forKey:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    
    {
        UITableViewCell *buttonCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        buttonCell.accessoryType = UITableViewCellAccessoryNone;
        buttonCell.editingAccessoryType = UITableViewCellAccessoryNone;
        
        buttonCell.textLabel.text = @"Log In";
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            buttonCell.textLabel.textColor = [UIColor MITTintColor];
            buttonCell.textLabel.textAlignment = NSTextAlignmentLeft;
        } else {
            buttonCell.textLabel.textAlignment = NSTextAlignmentCenter;
        }

        self.logInCell = buttonCell;

        [self setLogInButtonEnabled:NO];
        
        [cells setObject:buttonCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:1]];
    }
    
    {
        UISwitch *saveToggle = [[[UISwitch alloc] init] autorelease];

        NSDictionary *credentials = MobileKeychainFindItem(MobileLoginKeychainIdentifier, NO);

        saveToggle.on = [credentials objectForKey:(id)kSecAttrAccount] && ([self.password length] > 0);
        self.saveCredentials = saveToggle;

        UITableViewCell *saveCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        saveCell.selectionStyle = UITableViewCellSelectionStyleNone;
        saveCell.accessoryView = saveToggle;
        
        saveCell.textLabel.text = @"Remember Login";
        
        [cells setObject:saveCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:2]];
    }

    self.tableCells = cells;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    self.title = @"Touchstone";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelButtonPressed:)] autorelease];
    [self setupTableCells];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.activityView = [[[MITNavigationActivityView alloc] init] autorelease];
}

#pragma mark - Event Handlers
- (IBAction)cancelButtonPressed:(id)sender {
    if (self.delegate) {
        [self.delegate cancelWasPressedForLoginRequest:self];
    }
    
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)logInButtonPressed:(id)sender {
    if (self.delegate)
    {
        [self.delegate loginRequest:self
                 didEndWithUsername:self.usernameField.text
                           password:self.passwordField.text
                    shouldSaveLogin:self.shouldSaveLogin];
    }
    
    self.showActivityView = YES;
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Dynamic Property Methods
- (void)setShowActivityView:(BOOL)showView
{
    if (showView)
    {
        if (self.navigationItem.titleView == nil)
        {
            self.navigationItem.leftBarButtonItem.enabled = NO;
            [self setLogInButtonEnabled:NO];
            
            [self.usernameField resignFirstResponder];
            self.usernameField.userInteractionEnabled = NO;
            
            [self.passwordField resignFirstResponder];
            self.passwordField.userInteractionEnabled = NO;
            
            self.navigationItem.titleView = self.activityView;
            [self.activityView startActivityWithTitle:@"Authenticating..."];
        }
    }
    else
    {
        if (self.navigationItem.titleView)
        {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            [self setLogInButtonEnabled:YES];
            
            self.usernameField.userInteractionEnabled = YES;
            self.passwordField.userInteractionEnabled = YES;
            
            [self.activityView stopActivity];
            self.navigationItem.titleView = nil;
        }
    }
}

- (BOOL)showActivityView
{
    return (self.navigationItem.titleView == self.activityView);
}

- (BOOL)shouldSaveLogin
{
    return self.saveCredentials.isOn;
}


#pragma mark - Public Methods
- (void)authenticationDidFailWithError:(NSString*)error
                             willRetry:(BOOL)retry
{
    self.showActivityView = NO;
    self.dismissAfterAlert = !retry;
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Touchstone"
                                                     message:error
                                                    delegate:self
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK",nil] autorelease];
    alert.delegate = self;
    [alert show];
}

- (void)authenticationDidSucceed
{
    self.showActivityView = NO;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Private Methods

- (BOOL)logInButtonEnabled {
    return self.logInCell.textLabel.enabled;
}

- (void)setLogInButtonEnabled:(BOOL)enabled {
    self.logInCell.textLabel.enabled = enabled;
    self.logInCell.selectionStyle = (enabled) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
}


#pragma mark - UITextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // TODO: Make this disable the Log In button when a single backspace clears the entire password field.
    //   In that case, string == @"" and range == {6, 1}, which seems like a bug in -textField:shouldChangeCharactersInRange:replacementString:.
    NSInteger lengthChange = ([string length]) ? [string length] : -range.length;
    if (textField == self.usernameField)
    {
        [self setLogInButtonEnabled:(([textField.text length] + lengthChange) > 0) && ([self.passwordField.text length] > 0)];
    }
    else
    {
        [self setLogInButtonEnabled:(([textField.text length] + lengthChange) > 0) && ([self.usernameField.text length] > 0)];
    }
    
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        return NO;
    } else if ([string isEqualToString:@"\t"]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.usernameField])
    {
        [self.passwordField becomeFirstResponder];
    }
    else
    {
        [textField resignFirstResponder];
    }
    
    return NO;
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.dismissAfterAlert)
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - UITableView Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableCells objectForKey:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger maxSection = 0;
    
    for (NSIndexPath *indexPath in self.tableCells)
    {
        if (indexPath.section > maxSection)
        {
            maxSection = indexPath.section;
        }
    }
    
    return (maxSection + 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount = 0;
    
    for (NSIndexPath *indexPath in self.tableCells)
    {
        if (indexPath.section == section)
        {
            ++rowCount;
        }
    }
    
    return rowCount;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // section 1 == log in button
    if (indexPath.section == 1 && [self logInButtonEnabled]) {
        [self logInButtonPressed:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    // section 1 == log in button
    if (section == 1) {
        // TODO: move these user-visible strings out of code
        NSString *labelText = @"Log in with your MIT Kerberos username or Touchstone Collaboration Account to continue.";
        ExplanatorySectionLabel *footerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
        footerLabel.text = labelText;
        return footerLabel;
    }
    return nil;
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
