#import "MITTouchstoneMessage.h"

@interface MITECPResponseMessage : MITTouchstoneMessage
@property (nonatomic,readonly,strong) NSURL *assertionConsumerServiceURL;
@property (nonatomic,readonly) xmlNodePtr relayState;

- (instancetype)initWithData:(NSData*)xmlData relayState:(xmlNodePtr)relayState;
@end
