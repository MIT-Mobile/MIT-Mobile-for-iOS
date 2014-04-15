#import "MITTouchstoneMessage.h"

@interface MITECPAuthnRequestMessage : MITTouchstoneMessage
@property (nonatomic,readonly) xmlNodePtr relayState;
@property (nonatomic,readonly,strong) NSURL *responseConsumerURL;

- (instancetype)initWithData:(NSData*)xmlData;

@end
