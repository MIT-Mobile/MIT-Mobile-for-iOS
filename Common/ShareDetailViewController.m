#import "ShareDetailViewController.h"
#import "MIT_MobileAppDelegate.h"
#import "UIKit+MITAdditions.h"
#import "MITMailComposeController.h"
#import "Secret.h"
#import <Twitter/Twitter.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

static NSString *kShareDetailEmail = @"Email";
static NSString *kShareDetailFacebook = @"Facebook";
static NSString *kShareDetailTwitter = @"Twitter";

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
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailEmail])
    {
        [MITMailComposeController presentMailControllerWithRecipient:nil
                                                             subject:[self.shareDelegate emailSubject]
                                                                body:[self.shareDelegate emailBody]];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailFacebook])
    {
        [self composeForServiceType:SLServiceTypeFacebook];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:kShareDetailTwitter])
    {
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
@end
