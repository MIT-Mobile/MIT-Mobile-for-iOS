#import "MITMailComposeController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITLogging.h"

@interface MITMailComposeController ()
@property (nonatomic, weak) id<MFMailComposeViewControllerDelegate> mailComposeDelegate;
@end

@implementation MITMailComposeController
@synthesize completionBlock = _completionBlock;

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body
{
    [self presentMailControllerWithRecipient:email
                                     subject:subject
                                        body:body
                             completionBlock:nil];
}

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body completionBlock:(MITMailComposeCompleteBlock)completionBlock
{
    if ([MFMailComposeViewController canSendMail]) {
        MITMailComposeController *mailViewController = [[MITMailComposeController alloc] init];
        mailViewController.completionBlock = completionBlock;
        
        if ([email length])
        [mailViewController setToRecipients:@[email]];
         
        if ([subject length]) {
            [mailViewController setSubject:subject];
        }
        if ([body length]) {
            [mailViewController setMessageBody:body
                                        isHTML:NO];
        }
		
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate presentAppModalViewController:mailViewController
                                          animated:YES];
    }
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self _setMailComposeDelegate:self];
    }
    
    return self;
}

- (void)_setMailComposeDelegate:(id<MFMailComposeViewControllerDelegate>)mailComposeDelegate
{
    [super setMailComposeDelegate:mailComposeDelegate];
}

- (void)setMailComposeDelegate:(id<MFMailComposeViewControllerDelegate>)mailComposeDelegate
{
    return;
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    if ([controller isKindOfClass:[MITMailComposeController class]])
    {
        MITMailComposeController *mitController = (MITMailComposeController*)controller;
        if (mitController.completionBlock)
        {
            mitController.completionBlock(mitController, result, error);
        } else {
            DDLogError(@"No handler set for the mailComposeDelegate.");
        }
    }
    
    [controller dismissModalViewControllerAnimated:YES];
}

@end
