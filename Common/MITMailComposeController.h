#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

@class MITMailComposeController;

// TODO: add protocol for classes to do things after the controller is dismissed
typedef void(^MITMailComposeCompleteBlock)(MITMailComposeController *, MFMailComposeResult, NSError *);

@interface MITMailComposeController : MFMailComposeViewController <MFMailComposeViewControllerDelegate>
@property (nonatomic, copy) MITMailComposeCompleteBlock completionBlock;

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body;

// Set a completionBlock if you want to handle the MFMailComposeResult yourself. Note that means you'll have to dismiss the modal view.

+ (void)presentMailControllerWithRecipient:(NSString *)email
                                   subject:(NSString *)subject
                                      body:(NSString *)body
                           completionBlock:(MITMailComposeCompleteBlock)completionBlock;
@end
