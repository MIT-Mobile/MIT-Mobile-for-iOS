#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "TwitterViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITMailComposeController.h"
#import "Secret.h"

@implementation ShareDetailViewController

@synthesize fbSession, shareDelegate;

/*
- (id)init
{
	self = [super init];
	if (self) {
		actionSheetTitle = nil;
		emailSubject = nil;
		emailBody = nil;
	}
	return self;
}
*/

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}	

#pragma mark Action Sheet

// subclasses should make sure actionSheetTitle is set up before this gets called
// or call [super share:sender] at the end of this
- (void)share:(id)sender {
	UIActionSheet *shareSheet = [[UIActionSheet alloc] initWithTitle:[self.shareDelegate actionSheetTitle]
															delegate:self
												   cancelButtonTitle:@"Cancel"
											  destructiveButtonTitle:nil
												   otherButtonTitles:@"Email", @"Facebook", @"Twitter", nil];
    [shareSheet showFromAppDelegate];
    [shareSheet release];
}

// subclasses should make sure emailBody and emailSubject are set up before this gets called
// or call [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex] at the end of this
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// Email
        [MITMailComposeController presentMailControllerWithRecipient:nil subject:[self.shareDelegate emailSubject] body:[self.shareDelegate emailBody]];
	}
    else if (buttonIndex == 1) {
		// Facebook session
		[self showFacebookDialog];
	}
	else if (buttonIndex == 2) {
		[self showTwitterView];
	}
}

#pragma mark -
#pragma mark Facebook delegation

- (void)showFacebookDialog {
	BOOL resuming = NO;
	if (!self.fbSession && !(self.fbSession = [FBSession session])) {
		self.fbSession = [FBSession sessionForApplication:FacebookAPIKey secret:FacebookAPISecret delegate:self];
		resuming = [self.fbSession resume];
	}
	
	if (!self.fbSession.isConnected) {
		FBLoginDialog* dialog = [[[FBLoginDialog alloc] initWithSession:self.fbSession] autorelease];
		[dialog show];
	} else if (!resuming) {
		[self postItemToFacebook];
	}
}

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	[self postItemToFacebook];
}

- (void)postItemToFacebook {
	FBStreamDialog* dialog = [[[FBStreamDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.userMessagePrompt = [self.shareDelegate fbDialogPrompt];
	dialog.attachment = [self.shareDelegate fbDialogAttachment];
	[dialog show];
}

#pragma mark -
#pragma mark Share by Twitter

- (void)showTwitterView {
	UIViewController *twitterVC = [[TwitterViewController alloc] initWithMessage:[self.shareDelegate twitterTitle]
																			 url:[self.shareDelegate twitterUrl]];	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate presentAppModalViewController:twitterVC animated:YES];
	[twitterVC release];
}


#pragma mark -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [fbSession release];
    [super dealloc];
}


@end
