#import "TwitterViewController.h"
#import "MITUIConstants.h"
#import "MITConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "Secret.h"

#define TwitterRequestType @"TwitterRequestType"
#define VerifyCredentials @"VerifyCredentials"
#define SendTweet @"SendTweet"
#define CredentialsKey @"Credentials"
#define TwitterServiceName @"Twitter"

#define INPUT_FIELDS_MARGIN 10.0
#define INPUT_FIELDS_HEIGHT 32.0
#define INPUT_FIELDS_TOP 69.0
#define INPUT_FIELDS_FONT [UIFont systemFontOfSize:15];

#define INSTRUCTIONS_MARGIN 15.0
#define INSTRUCTIONS_HEIGHT 20.0
#define INSTRUCTIONS_TOP 30.0

#define MESSAGE_HEIGHT 157.0
#define MESSAGE_MARGIN 7.0

#define BOTTOM_SECTION_TOP 5.0
#define BOTTOM_SECTION_HEIGHT 30.0

#define USERNAME_MAX_WIDTH 150.0

MIT_MobileAppDelegate *appDelegate();

@interface TwitterViewController (Private)

- (void) loadLoginView;
- (void) loadMessageInputView;
- (void) updateMessageInputView;
- (void) dismissTwitterViewController;
- (void) updateTwitterSessionUI;

- (void) logoutTwitter;
- (void) loginTwitter;
- (void) sendTweet;

@end

@implementation TwitterViewController

- (id) initWithMessage: (NSString *)aMessage url:(NSString *)aLongUrl {
	self = [super init];
	if (self) {
		passwordField = nil;
		usernameField = nil;
		
		messageField = nil;	
		usernameLabel = nil;
		signOutButton = nil;
		
		loginView = nil;
		messageInputView = nil;
		
		contentView = nil;
		navigationItem = nil;
		
		message = [aMessage retain];
		longUrl = [aLongUrl retain];
		
		twitterEngine = nil;
		
		authenticationRequestInProcess = NO;
	}
	return self;
}

- (void) dealloc {
	[usernameField.delegate release];
	[passwordField.delegate release];
	[messageField.delegate release];
	
	[messageInputView release];
	[messageField release];
	[usernameLabel release];
	[signOutButton release];
	
	[loginView release];
	[usernameField release];
	[passwordField release];
	
	[message release];
	[longUrl release];
	
	// close all connections to twitter (This is probably the ideal UI)
	// additionally we really dont have a choice since the twitterEngine has no way of setting delegate = nil
	if(authenticationRequestInProcess) {
		[appDelegate() hideNetworkActivityIndicator];
	}
	
	for(NSString *identifier in [twitterEngine connectionIdentifiers]) {
		[twitterEngine closeConnection:identifier];
		[appDelegate() hideNetworkActivityIndicator];
	}
	[twitterEngine release];
    [super dealloc];
}

- (void) loadView {
	[super loadView];
	
	twitterEngine = [[XAuthTwitterEngine alloc] initXAuthWithDelegate:self];
	twitterEngine.consumerKey = TwitterOAuthConsumerKey;
	twitterEngine.consumerSecret = TwitterOAuthConsumerSecret;
	
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	appFrame.origin.y = 0;
	self.view = [[[UIView alloc] initWithFrame:appFrame] autorelease];
	
	CGRect navBarFrame = appFrame;
	navBarFrame.size.height = NAVIGATION_BAR_HEIGHT;	
	UINavigationBar *navBar = [[[UINavigationBar alloc] initWithFrame:navBarFrame] autorelease];
	navBar.barStyle= UIBarStyleBlack;
	navigationItem = [[[UINavigationItem alloc] initWithTitle:@"Twitter"] autorelease];
	navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissTwitterViewController)] autorelease];
	navBar.items = [NSArray arrayWithObject:navigationItem];
	
	self.view.opaque = YES;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
	[self.view addSubview:navBar];
	[self updateTwitterSessionUI];
}

- (void) updateTwitterSessionUI {
	[contentView removeFromSuperview];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey]) {
		// user has logged in so we show them the message input view
		[self loadMessageInputView];
		contentView = messageInputView;
		[messageField becomeFirstResponder];
		navigationItem.title = @"Post to Twitter";
		navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tweet" style:UIBarButtonItemStyleDone target:self action:@selector(sendTweet)] autorelease];
		[self updateMessageInputView];
		
	} else {
		// user has not yet logged in, so show them the login view
		[self loadLoginView];
		contentView = loginView;
		navigationItem.title = @"Sign in to Twitter";
		navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Sign in" style:UIBarButtonItemStyleDone target:self action:@selector(loginTwitter)] autorelease];
		[usernameField becomeFirstResponder];
	}
	
	[self.view addSubview:contentView];
}
	
- (void) dismissTwitterViewController {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) loadMessageInputView {
	if (!messageInputView) {
		CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
		contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
		contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;
		messageInputView = [[UIView alloc] initWithFrame:contentFrame];
		
		UILabel *counterLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
			contentFrame.size.width-MESSAGE_MARGIN-40, 
			MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, 
			40, 
			BOTTOM_SECTION_HEIGHT)] autorelease];
		counterLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
		counterLabel.backgroundColor = [UIColor clearColor];
		counterLabel.textColor = CELL_STANDARD_FONT_COLOR;
		counterLabel.textAlignment = UITextAlignmentRight;
		
		usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
			MESSAGE_MARGIN, 
			MESSAGE_HEIGHT+BOTTOM_SECTION_TOP,
			USERNAME_MAX_WIDTH, 
			BOTTOM_SECTION_HEIGHT)];
		usernameLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
		usernameLabel.backgroundColor = [UIColor clearColor];
		usernameLabel.textColor = [UIColor blackColor];
	
		CGRect messageFrame = CGRectMake(
			0,
			0, 
			contentFrame.size.width,
			MESSAGE_HEIGHT - 2);
		
		messageField = [[UITextView alloc] initWithFrame:messageFrame];
		messageField.text = [NSString stringWithFormat:@"%@:\n%@", message, longUrl];
		messageField.delegate = [[MessageFieldDelegate alloc] initWithMessage:messageField.text counter:counterLabel];
		messageField.font = [UIFont systemFontOfSize:17.0];
		
		signOutButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		UIImage *signOutImage = [UIImage imageNamed:@"global/twitter_signout.png"];
		UIImage *signOutImagePressed = [UIImage imageNamed:@"global/twitter_signout_pressed.png"];
		[signOutButton setImage:signOutImage forState:UIControlStateNormal];
		[signOutButton setImage:signOutImagePressed forState:(UIControlStateNormal | UIControlStateHighlighted)];
		signOutButton.frame = CGRectMake(USERNAME_MAX_WIDTH, MESSAGE_HEIGHT+BOTTOM_SECTION_TOP, signOutImage.size.width, signOutImage.size.height);
		[signOutButton addTarget:self action:@selector(logoutTwitter) forControlEvents:UIControlEventTouchUpInside];
		
		[messageInputView addSubview:signOutButton];
		[messageInputView addSubview:usernameLabel];
		[messageInputView addSubview:messageField];
		[messageInputView addSubview:counterLabel];
	}
}

- (void) updateMessageInputView {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	usernameLabel.text = username;	
	// make sure sign out button is aligned directly left of username
	CGRect frame = signOutButton.frame;
	frame.origin.x = 2*MESSAGE_MARGIN + [username sizeWithFont:usernameLabel.font].width;
	signOutButton.frame = frame;
}

- (void) loadLoginView {
	if (!loginView) {
		CGRect contentFrame = [[UIScreen mainScreen] applicationFrame];
		contentFrame.origin.y = NAVIGATION_BAR_HEIGHT;
		contentFrame.size.height = contentFrame.size.height - NAVIGATION_BAR_HEIGHT;
		loginView = [[UIView alloc] initWithFrame:contentFrame];	

		UILabel *instructionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(
			INSTRUCTIONS_MARGIN, 
			INSTRUCTIONS_TOP,
			contentFrame.size.width - 2 * INSTRUCTIONS_MARGIN,																  
			INSTRUCTIONS_HEIGHT
		)] autorelease];
		instructionLabel.numberOfLines = 0;
		instructionLabel.textAlignment = UITextAlignmentCenter;
		instructionLabel.text = @"Please sign into your Twitter account.";
		instructionLabel.font = [UIFont fontWithName:STANDARD_FONT size:STANDARD_CONTENT_FONT_SIZE];
		instructionLabel.backgroundColor = [UIColor clearColor];
		
	    CGFloat fieldWidth = contentFrame.size.width - 2 * INPUT_FIELDS_MARGIN;
		
		passwordField = [[UITextField alloc] initWithFrame:CGRectMake(
			INPUT_FIELDS_MARGIN, 
			INPUT_FIELDS_TOP+INPUT_FIELDS_HEIGHT+INPUT_FIELDS_MARGIN,
			fieldWidth, 
			INPUT_FIELDS_HEIGHT)];
		passwordField.borderStyle = UITextBorderStyleRoundedRect;
		passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		passwordField.font = INPUT_FIELDS_FONT;
		passwordField.placeholder = @"Password";
		passwordField.secureTextEntry = YES;
		passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
		passwordField.returnKeyType = UIReturnKeyGo;
		PasswordFieldDelegate *passwordDelegate = [[PasswordFieldDelegate alloc] init];
		passwordDelegate.delegate = self;
		passwordField.delegate = passwordDelegate;
	
		usernameField = [[UITextField alloc] initWithFrame:CGRectMake(INPUT_FIELDS_MARGIN, INPUT_FIELDS_TOP, fieldWidth, INPUT_FIELDS_HEIGHT)];
		usernameField.borderStyle = UITextBorderStyleRoundedRect;
		usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		usernameField.font = INPUT_FIELDS_FONT;
		usernameField.placeholder = @"Username";
		usernameField.returnKeyType = UIReturnKeyNext;
		usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
		usernameField.delegate = [[UsernameFieldDelegate alloc] initWithPasswordField:passwordField];
        usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	
		[loginView addSubview:instructionLabel];
		[loginView addSubview:usernameField];
		[loginView addSubview:passwordField];
	}
}

- (void) logoutTwitter {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:TwitterShareUsernameKey];
	
	NSError *error = nil;
	[SFHFKeychainUtils deleteItemForUsername:username andServiceName:TwitterServiceName error:&error];

	[self updateTwitterSessionUI];
}
	
- (void) loginTwitter {
	[twitterEngine exchangeAccessTokenForUsername:usernameField.text password:passwordField.text];
	authenticationRequestInProcess = YES;
	navigationItem.rightBarButtonItem.enabled = NO;
	[appDelegate() showNetworkActivityIndicator];
}

- (void) sendTweet {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterShareUsernameKey];
	[twitterEngine setUsername:username password:nil];

	[twitterEngine sendUpdate:messageField.text];
	
	[appDelegate() showNetworkActivityIndicator];
}
	
- (NSString *) cachedTwitterXAuthAccessTokenStringForUsername: (NSString *)username {
	NSError *error = nil;
	NSString *accessToken = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:TwitterServiceName error:&error];
	if (error) {
		ELog(@"something went wrong looking up access token, error=%@", error);
		return nil;
	} else {
		return accessToken;
	}
}

- (void)storeCachedTwitterXAuthAccessTokenString:(NSString *)accessToken forUsername:(NSString *)username {
	[[NSUserDefaults standardUserDefaults] setObject:username forKey:TwitterShareUsernameKey];
	NSError *error = nil;
	[SFHFKeychainUtils storeUsername:username andPassword:accessToken forServiceName:TwitterServiceName updateExisting:YES error:&error];
	
	navigationItem.rightBarButtonItem.enabled = YES;
	authenticationRequestInProcess = NO;
	[appDelegate() hideNetworkActivityIndicator];
	
	if (!error) {
		[self updateTwitterSessionUI];
	} else {
		ELog(@"error on saving token=%@",error);
	}
}
	
- (void)twitterXAuthConnectionDidFailWithError:(NSError *)error {
	NSString *errorMsg;
	if(error.code == -1012) {
		errorMsg = @"Twitter was unable to authenticate your username and/or password";
	} else if (error.code == -1009) {
		errorMsg = @"Failed to connect to the twitter server";
	} else	{
		errorMsg = @"Something went wrong while trying to authenicate your twitter account";
		ELog(@"unusual error=%@", error);
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Twitter Failure" 
		message:errorMsg 
		delegate:nil 
		cancelButtonTitle:@"OK" 
		otherButtonTitles:nil];
	[alertView show];
	[alertView release];
	navigationItem.rightBarButtonItem.enabled = YES;
	authenticationRequestInProcess = NO;
	[appDelegate() hideNetworkActivityIndicator];
}
	
- (void)requestSucceeded:(NSString *)connectionIdentifier {
	[appDelegate() hideNetworkActivityIndicator];
	[self dismissTwitterViewController];
}
					 
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
	[appDelegate() hideNetworkActivityIndicator];
	
	NSString *errorTitle;
	NSString *errorMessage;
	
	if (error.code == 401) {
		errorTitle = @"Login failed";
		errorMessage = @"Twitter username and password is not recognized";
		[self logoutTwitter];
	} else {
		errorTitle = @"Network failed";
		errorMessage = @"Failure connecting to Twitter";
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] 
							  initWithTitle:errorTitle 
							  message:errorMessage
							  delegate:nil 
							  cancelButtonTitle:@"Cancel" 
							  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

@end

@implementation UsernameFieldDelegate

- (id) initWithPasswordField: (UITextField *)aPasswordField {
	self = [super init];
	if (self) {
		passwordField = [aPasswordField retain];
	}
	return self;
}

- (void) dealloc {
	[passwordField release];
	[super dealloc];
}

- (BOOL) textFieldShouldReturn: (UITextField *)textField {
	[textField resignFirstResponder];
	[passwordField becomeFirstResponder];
	return YES;
}

@end

@implementation PasswordFieldDelegate 
@synthesize delegate;

- (BOOL) textFieldShouldReturn: (UITextField *)textField {
	[delegate loginTwitter];
	return YES;
}

@end

@interface MessageFieldDelegate (Private)
- (void) updateCounter: (NSString *)message delta:(NSInteger)deltaChars;
@end

@implementation MessageFieldDelegate 

- (id) initWithMessage: (NSString *)message counter: (UILabel *)aCounter {
	self = [super init];
	if (self) {
		counter = [aCounter retain];
		[self updateCounter:message delta:0];
	}
	return self;
}

- (void) dealloc {
	[counter release];
	[super dealloc];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if(textView.text.length - range.length + text.length <= 140) {
		[self updateCounter:textView.text delta:text.length-range.length];
		return YES;
	} else {
		return NO;
	}
}

- (void) updateCounter: (NSString *)message delta:(NSInteger)deltaChars{
	counter.text = [NSString stringWithFormat:@"%i", 140-[message length]-deltaChars];
}

@end

MIT_MobileAppDelegate *appDelegate() {
	return (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
}

