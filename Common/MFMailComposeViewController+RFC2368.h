#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (RFC2368)
- (id)initWithURL:(NSURL*)mailtoUrl;
@end
