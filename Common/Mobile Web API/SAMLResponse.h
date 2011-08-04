#import <Foundation/Foundation.h>
//#import "MITConstants.h"

@interface SAMLResponse : NSObject <NSXMLParserDelegate>
@property (nonatomic,readonly,retain) NSURL* postURL;
@property (nonatomic,readonly,copy) NSString* samlResponse;
@property (nonatomic,readonly,copy) NSString* relayState;
@property (nonatomic,readonly,retain) NSError* error;

- (id)initWithResponseData:(NSData*)response;
@end
