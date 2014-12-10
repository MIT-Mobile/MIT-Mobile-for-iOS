#import <Twitter/Twitter.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <Accounts/Accounts.h>

#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "Secret.h"

static NSString *kShareDetailEmail = @"Email";
static NSString *kShareDetailFacebook = @"Facebook";
static NSString *kShareDetailTwitter = @"Twitter";

@interface ShareDetailViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation ShareDetailViewController
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
    if (self.shareDelegate)
    {
        UIActionSheet *sheet = nil;
        
        sheet = [[UIActionSheet alloc] initWithTitle:[self.shareDelegate actionSheetTitle]
                                            delegate:self
                                   cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:nil
                                   otherButtonTitles:kShareDetailEmail, kShareDetailFacebook, kShareDetailTwitter,nil];
        
        [sheet showInView:self.view];
    }
}

// subclasses should make sure emailBody and emailSubject are set up before this gets called
// or call [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex] at the end of this
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailEmail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
        [composeViewController setSubject:[self.shareDelegate emailSubject]];
        [composeViewController setMessageBody:[self.shareDelegate emailBody] isHTML:NO];
        [self presentViewController:composeViewController animated:YES completion:nil];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailFacebook]) {
        [self composeForServiceType:SLServiceTypeFacebook];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailTwitter]) {
        [self composeForServiceType:SLServiceTypeTwitter];
    }
}

- (void)composeForServiceType:(NSString*)serviceType
{
        SLComposeViewController *composeView = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        [composeView setInitialText:[self.shareDelegate twitterTitle]];
        composeView.completionHandler = ^(SLComposeViewControllerResult result) {
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    DDLogVerbose(@"Compose Canceled");
                    break;
                    
                case SLComposeViewControllerResultDone:
                    DDLogVerbose(@"Compose Finished");
                    break;
            }
            
            [self dismissViewControllerAnimated:YES completion:NULL];
        };
        
        NSURL *sharedURL = [NSURL URLWithString:[self.shareDelegate twitterUrl]];
        if (sharedURL)
        {
            [composeView addURL:sharedURL];
        }
        
        if ([self.shareDelegate respondsToSelector:@selector(postImage)])
        {
            UIImage *image = [self.shareDelegate postImage];
            if (image)
            {
                [composeView addImage:image];
            }
        }
        
        [self presentViewController:composeView
                           animated:YES
                         completion:nil];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ([self.presentedViewController isEqual:controller]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
