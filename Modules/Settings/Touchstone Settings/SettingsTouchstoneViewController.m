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

@property (nonatomic,retain) MobileRequestOperation *authOperation;
@property (nonatomic,retain) NSDictionary *tableCells;
@property (nonatomic,assign) UITextField *usernameField;
@property (nonatomic,assign) UITextField *passwordField;
@property (nonatomic,assign) UIButton *logoutButton;
- (void)setupTableCells;
- (IBAction)clearTouchstoneLogin:(id)sender;

- (void)save:(id)sender;
- (void)cancel:(id)sender;
- (void)saveWithUsername:(NSString*)username password:(NSString*)password;
@end

@implementation SettingsTouchstoneViewController
@synthesize tableCells = _tableCells;
@synthesize authOperation = _authOperation;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize logoutButton = _logoutButton;
@synthesize authenticationFailed = _authenticationFailed;

+ (NSString*)touchstoneUsername
{
    NSDictionary *accountInfo = MobileKeychainFindItem(MobileLoginKeychainIdentifier, NO);
    
    return [accountInfo objectForKey:(id)kSecAttrAccount];
}

- (id)init
{
    self = [super initWithNibName:nil
                           bundle:nil];
    if (self) {
        self.authenticationFailed = NO;
    }
    return self;
}

- (void)dealloc
{
    self.tableCells = nil;
    
    if (self.authOperation)
    {
        [self.authOperation cancel];
        self.authOperation = nil;
    }
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)loadView
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    UIView *mainView = [[[UIView alloc] initWithFrame:screenRect] autorelease];
    
    CGRect viewBounds = mainView.bounds;
    {
        [self setupTableCells];
        
        CGRect tableFrame = viewBounds;
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame
                                                              style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 44.0;
        tableView.allowsSelection = NO;
        tableView.scrollEnabled = NO;
        tableView.backgroundColor = [UIColor clearColor];
        
        viewBounds.origin.y += tableFrame.size.height;
        [mainView addSubview:tableView];
    }
    
    [self setView:mainView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Touchstone";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem.tag = NSIntegerMax;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)] autorelease];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private Methods
- (void)setupTableCells
{
    UIEdgeInsets textCellInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    
    NSDictionary *credentials = MobileKeychainFindItem(MobileLoginKeychainIdentifier, YES);
    
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
        userField.minimumFontSize = 10.0;
        userField.placeholder = @"Username or Email";
        userField.returnKeyType = UIReturnKeyNext;
        userField.textAlignment = UITextAlignmentLeft;
        
        NSString *username = (NSString*)[credentials objectForKey:(id)kSecAttrAccount];
        if ([username length]) {
            userField.text = username;
        }
        
        userField.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, 320, 44), textCellInsets);
        self.usernameField = userField;
        [usernameCell.contentView addSubview:userField];
        
        [cells setObject:usernameCell
                  forKey:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    {
        UITableViewCell *passwordCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITextField *passField = [[[UITextField alloc] init] autorelease];
        passField.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                      UIViewAutoresizingFlexibleWidth);
        passField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        passField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passField.delegate = self;
        passField.placeholder = @"Password";
        passField.returnKeyType = UIReturnKeyDone;
        passField.secureTextEntry = YES;
        
        NSString *password = (NSString*)[credentials objectForKey:(id)kSecValueData];
        if ([password length]) {
            passField.text = password;
        }
        
        passField.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, 320, 44), textCellInsets);
        
        self.passwordField = passField;
        [passwordCell.contentView addSubview:passField];
        
        [cells setObject:passwordCell
                  forKey:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    
    {
        UITableViewCell *buttonCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        buttonCell.accessoryType = UITableViewCellAccessoryNone;
        buttonCell.editingAccessoryType = UITableViewCellAccessoryNone;
        buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
        buttonCell.backgroundColor = [UIColor clearColor];
        
        UIView *transparentView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,320,44)] autorelease];
        transparentView.backgroundColor = [UIColor clearColor];
        [buttonCell setBackgroundView:transparentView];
        
        UIEdgeInsets buttonInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        CGRect buttonFrame = CGRectMake(0,0,320,44);
        buttonFrame = UIEdgeInsetsInsetRect(buttonFrame, buttonInsets);
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        button.enabled = NO;
        button.frame = buttonFrame;
        
        NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [cookieStore cookies]) {
            if ([MobileRequestOperation isAuthenticationCookie:cookie]) {
                button.enabled = YES;
                break;
            }
        }
        
        
        [button setTitle:@"Log out of Touchstone"
                forState:UIControlStateNormal];
        [button setTitleColor:[UIColor lightGrayColor]
                          forState:UIControlStateDisabled];
        [button addTarget:self
                   action:@selector(clearTouchstoneLogin:)
              forControlEvents:UIControlEventTouchUpInside];
        
        [buttonCell addSubview:button];
        self.logoutButton = button;
        
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
    
    if ([username length])
    {
        if (self.authenticationFailed)
        {
            UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"You may not be able to login to Touchstone using the provided credentials. Are you sure you want to continue?"
                                                                delegate:self
                                                       cancelButtonTitle:@"Edit"
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:@"Save",nil] autorelease];
            [sheet showInView:self.view];
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else if ([password length] == 0)
        {
            [self saveWithUsername:username
                          password:password];
        }
        else if (self.authOperation == nil)
        {
            [self clearTouchstoneLogin:nil];

            MITNavigationActivityView *activityView = [[[MITNavigationActivityView alloc] init] autorelease];
            self.navigationItem.titleView = activityView;
            [activityView startActivityWithTitle:@"Verifying..."];
            
            self.authOperation = [MobileRequestOperation operationWithModule:@"libraries"
                                                                     command:@"getUserIdentity"
                                                                  parameters:nil];
            
            [self.authOperation authenticateUsingUsername:username
                                                 password:password];
            self.authOperation.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error)
            {
                self.authOperation = nil;
                self.navigationItem.titleView = nil;
                if (error)
                {
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    self.authenticationFailed = YES;
                    
                    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Touchstone Account"
                                                                    message:@"Unable to verify Touchstone credentials."
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil] autorelease];
                    
                    [alert show];
                }
                else
                {
                    [self saveWithUsername:username
                                  password:password];
                }
            };
            
            [self.authOperation start];
        }
    }
    else
    {
        DLog(@"Saved Touchstone password has been cleared");
        [self saveWithUsername:nil
                      password:nil];
    }
}

- (void)cancel:(id)sender
{
    if (self.authOperation)
    {
        [self.authOperation cancel];
    }
    
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if (section == 0) {
        UIImageView *secureIcon = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];

        // TODO: move these user-visible strings out of code
        NSString *labelText = @"A lock icon appears next to services requiring authentication. Use your MIT Kerberos username or Touchstone Collaboration Account to log in.";

        ExplanatorySectionLabel *footerLabel = [[[ExplanatorySectionLabel alloc] initWithType:ExplanatorySectionFooter] autorelease];
        footerLabel.text = labelText;
        footerLabel.accessoryView = secureIcon;
        return footerLabel;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSString *labelText = @"Features requiring authentication are marked with a lock icon. Use your MIT Kerberos username or Touchstone Collaboration Account to log in.";
        UIImageView *secureIcon = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
        CGFloat height = [ExplanatorySectionLabel heightWithText:labelText 
                                                          width:self.view.frame.size.width
                                                            type:ExplanatorySectionFooter
                                                   accessoryView:secureIcon];
        return height;
    }
    return 0;
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
    self.logoutButton.enabled = NO;
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.authenticationFailed = NO;
    
    if (self.navigationItem.rightBarButtonItem.tag == NSIntegerMax)
    {
        UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                               target:self
                                                                               action:@selector(save:)] autorelease];
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
