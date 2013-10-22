#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "MITMailComposeController.h"
#import "Secret.h"
#import "DEFacebookComposeViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Twitter/Twitter.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

static NSString *kShareDetailEmail = @"Email";
static NSString *kShareDetailFacebook = @"Facebook";
static NSString *kShareDetailTwitter = @"Twitter";

@interface ShareDetailViewController ()
- (void)showFacebookComposeDialog;
- (void)showTwitterComposeDialog;
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
        
        [sheet showFromAppDelegate];
    }
}

// subclasses should make sure emailBody and emailSubject are set up before this gets called
// or call [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex] at the end of this
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailEmail])
    {
        [MITMailComposeController presentMailControllerWithRecipient:nil
                                                             subject:[self.shareDelegate emailSubject]
                                                                body:[self.shareDelegate emailBody]];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailFacebook])
    {
        [self showFacebookComposeDialog];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailTwitter])
    {
        [self showTwitterComposeDialog];
    }
}

- (void)showFacebookComposeDialog
{
    BOOL newStyleSupported = NO;
    if ([SLComposeViewController class])
    {
        newStyleSupported = [self composeForServiceType:SLServiceTypeFacebook];
    }
    
    if (newStyleSupported == NO) {
        [self showLegacyFacebookDialog];
    }
}

- (void)showLegacyFacebookDialog
{
    DEFacebookComposeViewController *composeController = [[DEFacebookComposeViewController alloc] init];
    [composeController setInitialText:[self.shareDelegate twitterTitle]];
    [composeController addURL:[self.shareDelegate twitterUrl]];
    composeController.completionHandler = ^(DEFacebookComposeViewControllerResult result) {
        switch (result) {
            case DEFacebookComposeViewControllerResultCancelled:
                DDLogVerbose(@"Facebook Result: Cancelled");
                break;
            case DEFacebookComposeViewControllerResultDone:
                DDLogVerbose(@"Facebook Result: Sent");
                break;
        }
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:composeController
                       animated:YES
                     completion:nil];
}

- (void)showTwitterComposeDialog
{
    BOOL newStyleSupported = NO;
    
    if ([SLComposeViewController class])
    {
        newStyleSupported = [self composeForServiceType:SLServiceTypeTwitter];
    }
    
    if (newStyleSupported == NO)
    {
        TWTweetComposeViewController *tweetComposer = [[TWTweetComposeViewController alloc] init];
        [tweetComposer setInitialText:[self.shareDelegate twitterTitle]];
        
        NSURL *twURL = [NSURL URLWithString:[self.shareDelegate twitterUrl]];
        if (twURL)
        {
            [tweetComposer addURL:twURL];
        }
        
        if ([self.shareDelegate respondsToSelector:@selector(postImage)])
        {
            UIImage *image = [self.shareDelegate postImage];
            if (image)
            {
                [tweetComposer addImage:image];
            }
        }
    }
    
}

- (BOOL)composeForServiceType:(NSString*)serviceType
{
    if ([SLComposeViewController class])
    {
        if ([SLComposeViewController isAvailableForServiceType:serviceType])
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
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}
@end
