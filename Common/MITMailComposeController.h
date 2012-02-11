#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

// TODO: add protocol for classes to do things after the controller is dismissed

typedef void(^CompletionBlock)(MFMailComposeViewController *, MFMailComposeResult, NSError *);

@interface MITMailComposeController : NSObject <MFMailComposeViewControllerDelegate> {

}

@property (nonatomic, copy) CompletionBlock completionBlock;

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body;

// Set a completionBlock if you want to handle the MFMailComposeResult yourself. Note that means you'll have to dismiss the modal view.

+ (void)presentMailControllerWithRecipient:(NSString *)email subject:(NSString *)subject body:(NSString *)body completionBlock:(CompletionBlock)completionBlock;
@end
