#import "MITTouchstoneMessage.h"

@interface MITECPIdentityProviderResponse : MITTouchstoneMessage
@property (nonatomic,readonly,strong) NSURL *assertionConsumerServiceURL;
@property (nonatomic,readonly) xmlNodePtr relayState;

- (instancetype)initWithData:(NSData*)xmlData relayState:(xmlNodePtr)relayState;
@end
