#import "NSMutableURLRequest+ECP.h"
#import "MITTouchstoneConstants.h"

static inline NSString* MITTouchstoneAcceptHeaderValue() {
    NSArray *acceptedTypes = @[MITECPMIMEType,
                               @"application/json",
                               @"text/html"];
    return [acceptedTypes componentsJoinedByString:@"; "];
}

static inline NSString* MITTouchstonePAOSHeaderValue() {
    return [NSString stringWithFormat:@"ver=\"%@\"; \"%@\"",MITPAOSNamespaceURI,MITECPNamespaceURI];
}

@implementation NSMutableURLRequest (ECP)
- (void)setAdvertisesECP
{
    [self addValue:MITTouchstoneAcceptHeaderValue() forHTTPHeaderField:@"Accept"];
    [self setValue:MITTouchstonePAOSHeaderValue() forHTTPHeaderField:MITECPPAOSHeaderName];
}

@end
