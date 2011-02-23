//
//  MFMailComposeViewController+mailto.h
//
//  Created by Blake Skinner on 10/15/10.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (RFC2368)
- (id)initWithURL:(NSURL*)mailtoUrl;
@end
