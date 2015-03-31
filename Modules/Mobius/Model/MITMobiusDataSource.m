#import "MITMobiusDataSource.h"
#import "MITMobileServerConfiguration.h"

static NSString* const MITMobiusStableServer = @"https://kairos-test.mit.edu";
static NSString* const MITMobiusDevelopmentServer = @"https://kairos-dev.mit.edu";

@implementation MITMobiusDataSource
+ (NSURL*)mobiusServerURL
{
    MITMobileWebServerType serverType = MITMobileWebGetCurrentServerType();

    switch (serverType) {
        case MITMobileWebDevelopment:
            return [NSURL URLWithString:MITMobiusDevelopmentServer];
        case MITMobileWebStaging:
        case MITMobileWebProduction:
            return [NSURL URLWithString:MITMobiusStableServer];
    }
}

@end
