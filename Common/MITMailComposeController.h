#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

// TODO: add protocol for classes to do things after the controller is dismissed

@interface MITMailComposeController : NSObject <MFMailComposeViewControllerDelegate> {

}

+ (void)presentMailControllerWithEmail:(NSString *)email subject:(NSString *)subject body:(NSString *)body;

@end
