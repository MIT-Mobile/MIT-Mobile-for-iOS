#import "MITMailComposeController.h"
#import "MIT_MobileAppDelegate.h"

@implementation MITMailComposeController

+ (void)presentMailControllerWithEmail:(NSString *)email subject:(NSString *)subject body:(NSString *)body
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[MFMailComposeViewController alloc] init];
		aController.mailComposeDelegate = [[MITMailComposeController alloc] init]; // releases self when dismissed

		if (email != nil) {
            NSArray *toRecipient = [NSArray arrayWithObject:email]; 
            [aController setToRecipients:toRecipient];
        }
        if (subject != nil) {
            [aController setSubject:subject];
        }
        if (body != nil) {
            [aController setMessageBody:body isHTML:NO];
        }
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:aController animated:YES];
		[aController release];
		
	} else {
        NSMutableArray *array = [NSMutableArray array];
        if (subject != nil) {
            [array addObject:[NSString stringWithFormat:@"&subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        if (body != nil) {
             [array addObject:[NSString stringWithFormat:@"&body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        NSString *urlString = [NSString stringWithFormat:@"mailto:%@?%@",
                               (email != nil ? email : @""),
                               [array componentsJoinedByString:@"&"]];
        
		NSURL *externURL = [NSURL URLWithString:urlString];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate dismissAppModalViewControllerAnimated:YES];
    
    [self release];
}

@end
