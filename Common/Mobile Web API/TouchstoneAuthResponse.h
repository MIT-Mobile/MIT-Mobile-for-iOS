#import <Foundation/Foundation.h>
//#import "MITConstants.h"

@interface TouchstoneAuthResponse : NSObject <NSXMLParserDelegate>
@property (nonatomic,readonly,retain) NSString* postURLPath;
@property (nonatomic,readonly,retain) NSError* error;

- (id)initWithResponseData:(NSData*)response;
@end
