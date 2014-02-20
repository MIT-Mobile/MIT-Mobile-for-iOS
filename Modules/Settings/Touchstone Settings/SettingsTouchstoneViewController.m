#import "SettingsTouchstoneViewController.h"
#import "MobileKeychainServices.h"
#import "MobileRequestOperation.h"
#import "MITConstants.h"
#import "UIKit+MITAdditions.h"
#import "ExplanatorySectionLabel.h"
#import "MITNavigationActivityView.h"

enum {
    TouchstoneUserCell = 0,
    TouchstonePasswordCell
};

@interface SettingsTouchstoneViewController ()
@property (nonatomic) BOOL authenticationFailed;

@property (nonatomic,weak) MobileRequestOperation *authOperation;
@property (nonatomic,copy) NSDictionary *tableCells;
@property (nonatomic,weak) UITextField *usernameField;
@property (nonatomic,weak) UITextField *passwordField;
@property (nonatomic,weak) UITableViewCell *logoutCell;

- (void)setupTableCells;
- (IBAction)clearTouchstoneLogin:(id)sender;

- (void)save:(id)sender;
- (void)cancel:(id)sender;
- (void)saveWithUsername:(NSString*)username password:(NSString*)password;
@end

@implementation SettingsTouchstoneViewController
+ (NSString*)touchstoneUsername
{
    NSDictionary *accountInfo = MobileKeychainFindItem(MobileLoginKeychainIdentifier, NO);
    
    return accountInfo[(__bridge id)kSecAttrAccount];
}

- (id)init
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    [self.authOperation cancel];
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIView *mainView = [[UIView alloc] initWithFrame:screenRect];
    
    CGRect viewBounds = mainView.bounds;
    {
        [self setupTableCells];
        
        CGRect tableFrame = viewBounds;
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame
                                                              style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 44.0;
        tableView.allowsSelection = YES;
        tableView.scrollEnabled = NO;
        tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        tableView.backgroundView = nil;
        tableView.opaque = NO;
        
        viewBounds.origin.y += tableFrame.size.height;
        [mainView addSubview:tableView];
    }
    
    [self setView:mainView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"MIT Touchstone";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem.tag = NSIntegerMax;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private Methods
- (void)setupTableCells
{
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    UIEdgeInsets textCellInsets = UIEdgeInsetsMake(0, 15, 0, 15);
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        textCellInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    }
    CGRect fieldFrame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, 320, 44), textCellInsets);

    NSDictionary *credentials = MobileKeychainFindItem(MobileLoginKeychainIdentifier, YES);
    
    {
        UITableViewCell *usernameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITextField *userField = [[UITextField alloc] init];
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
        
        NSString *username = credentials[(__bridge id)kSecAttrAccount];
        if ([username length]) {
            userField.text = username;
        }
        
        userField.frame = fieldFrame;
        self.usernameField = userField;
        [usernameCell.contentView addSubview:userField];
        
        [cells setObject:usernameCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    {
        UITableViewCell *passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITextField *passField = [[UITextField alloc] init];
        passField.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleWidth);
        passField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        passField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passField.delegate = self;
        passField.font = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
        passField.placeholder = @"Password";
        passField.returnKeyType = UIReturnKeyDone;
        passField.secureTextEntry = YES;
        
        NSString *password = credentials[(__bridge id)kSecValueData];
        if ([password length]) {
            passField.text = password;
        }
        
        passField.frame = fieldFrame;
        
        self.passwordField = passField;
        [passwordCell.contentView addSubview:passField];
        
        [cells setObject:passwordCell
                  forKey:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    
    {
        UITableViewCell *buttonCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        buttonCell.accessoryType = UITableViewCellAccessoryNone;
        buttonCell.editingAccessoryType = UITableViewCellAccessoryNone;

        buttonCell.textLabel.text = @"Log out of Touchstone";
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            buttonCell.textLabel.textAlignment = NSTextAlignmentLeft;
            buttonCell.textLabel.textColor = [UIColor MITTintColor];
        } else {
            buttonCell.textLabel.textAlignment = NSTextAlignmentCenter;
            buttonCell.textLabel.textColor = [UIColor blackColor];
        }
        
        self.logoutCell = buttonCell;
        
        [self setLogOutButtonEnabled:NO];

        NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [cookieStore cookies]) {
            if ([MobileRequestOperation isAuthenticationCookie:cookie]) {
                [self setLogOutButtonEnabled:YES];
                break;
            }
        }
        
        [cells setObject:buttonCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:1]];
    }

    self.tableCells = cells;
}

- (void)save:(id)sender
{
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if ([username length]) {
        if (self.authenticationFailed) {
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"You may not be able to login to Touchstone using the provided credentials. Are you sure you want to continue?"
                                                                delegate:self
                                                       cancelButtonTitle:@"Edit"
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:@"Save",nil];
            [sheet showInView:self.view];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        } else if ([password length] == 0) {
            [self saveWithUsername:username
                          password:password];
        } else if (!self.authOperation) {
            [self clearTouchstoneLogin:nil];

            MITNavigationActivityView *activityView = [[MITNavigationActivityView alloc] init];
            self.navigationItem.titleView = activityView;
            [activityView startActivityWithTitle:@"Verifying..."];
            
            MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                                    command:@"getUserIdentity"
                                                                                 parameters:nil];
            
            [operation authenticateUsingUsername:username
                                        password:password];

            __weak SettingsTouchstoneViewController *weakSelf = self;
            operation.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
                SettingsTouchstoneViewController *blockSelf = weakSelf;
                blockSelf.authOperation = nil;
                blockSelf.navigationItem.titleView = nil;
                if (error) {
                    blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
                    blockSelf.authenticationFailed = YES;
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Touchstone Account"
                                                                    message:@"Unable to verify Touchstone credentials."
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                    
                    [alert show];
                } else {
                    [blockSelf saveWithUsername:username
                                  password:password];
                }
            };

            self.authOperation = operation;
            [[MobileRequestOperation defaultQueue] addOperation:operation];
        }
    } else {
        DDLogVerbose(@"Saved Touchstone password has been cleared");
        [self saveWithUsername:nil
                      password:nil];
    }
}

- (void)cancel:(id)sender
{
    [self.authOperation cancel];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveWithUsername:(NSString*)username password:(NSString*)password
{
    if ([username length])
    {
        MobileKeychainSetItem(MobileLoginKeychainIdentifier, username, password);
    }
    else
    {
        MobileKeychainDeleteItem(MobileLoginKeychainIdentifier);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)logOutButtonEnabled
{
    return self.logoutCell.textLabel.enabled;
}

- (void)setLogOutButtonEnabled:(BOOL)enabled
{
    self.logoutCell.textLabel.enabled = enabled;
    self.logoutCell.selectionStyle = (enabled) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
}

#pragma mark - UITableView Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableCells[indexPath];
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if (section == 0) {
        UIImageView *secureIcon = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];

        // TODO: move these user-visible strings out of code
        NSString *labelText = @"A lock icon will appear next to services requiring authentication. Use your MIT Kerberos username or Touchstone Collaboration Account to log in.";

        ExplanatorySectionLabel *footerLabel = [[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter];
        footerLabel.text = labelText;
        footerLabel.accessoryView = secureIcon;
        return footerLabel;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSString *labelText = @"A lock icon will appear next to services requiring authentication. Use your MIT Kerberos username or Touchstone Collaboration Account to log in.";
        UIImageView *secureIcon = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
        CGFloat height = [ExplanatorySectionLabel heightWithText:labelText 
                                                          width:self.view.frame.size.width
                                                            type:ExplanatorySectionFooter
                                                   accessoryView:secureIcon];
        return height;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableCells[indexPath] == self.logoutCell && [self logOutButtonEnabled] == YES) {
        [self clearTouchstoneLogin:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Notification Handlers
- (void)keyboardDidShow:(NSNotification*)notification
{
    
}

- (void)keyboardDidHide:(NSNotification*)notification
{
    
}

- (IBAction)clearTouchstoneLogin:(id)sender
{
    [MobileRequestOperation clearAuthenticatedSession];
    [self setLogOutButtonEnabled:NO];
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.authenticationFailed = NO;
    
    if (self.navigationItem.rightBarButtonItem.tag == NSIntegerMax)
    {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                               target:self
                                                                               action:@selector(save:)];
        item.tag = 0;
        [self.navigationItem setRightBarButtonItem:item
                                          animated:YES];
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

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle caseInsensitiveCompare:@"Save"] == NSOrderedSame)
    {
        [self saveWithUsername:self.usernameField.text
                      password:self.passwordField.text];
    }
}

#pragma mark - Touch Handlers
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}
@end
