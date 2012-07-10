#import "MITMailComposeController.h"
#import "MIT_MobileAppDelegate.h"

@implementation MITMailComposeController

@synthesize completionBlock = _completionBlock;

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body {
    [self presentMailControllerWithRecipient:email subject:subject body:body completionBlock:nil];
}

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body completionBlock:(CompletionBlock)completionBlock {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mfViewController = [[MFMailComposeViewController alloc] init];
        MITMailComposeController *mitController = [[MITMailComposeController alloc] init];
		mfViewController.mailComposeDelegate = mitController; // releases self when dismissed
        
		if (email != nil) {
            NSArray *toRecipient = [NSArray arrayWithObject:email]; 
            [mfViewController setToRecipients:toRecipient];
        }
        if (subject != nil) {
            [mfViewController setSubject:subject];
        }
        if (body != nil) {
            [mfViewController setMessageBody:body isHTML:NO];
        }
        
        // Use the completionBlock if it's there. Just dismiss the modal view otherwise. Release the MITMailComposeViewController regardless.
        if (completionBlock) {
            mitController.completionBlock = ^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
                completionBlock(controller, result, error);
                [mitController release];
            };
        } else {
            mitController.completionBlock = ^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
                MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate dismissAppModalViewControllerAnimated:YES];
                
                [mitController release];
            };
        }
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:mfViewController animated:YES];
        [mfViewController release];
    }
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if ([controller.mailComposeDelegate respondsToSelector:@selector(completionBlock)]) {
        MITMailComposeController *mitController = controller.mailComposeDelegate;
        CompletionBlock completionBlock = mitController.completionBlock;
        if (completionBlock) {
            completionBlock(controller, result, error);
        }
    } else {
        ELog(@"No handler set for the mailComposeDelegate.");
    }
}

@end
