#import "MITTouchstoneMessage.h"

@interface MITECPServiceProviderResponse : MITTouchstoneMessage
@property (nonatomic,readonly) xmlNodePtr relayState;
@property (nonatomic,readonly,strong) NSURL *responseConsumerURL;

- (instancetype)initWithData:(NSData*)xmlData;

@end
