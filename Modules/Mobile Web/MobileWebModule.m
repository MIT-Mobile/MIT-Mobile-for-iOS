#import "MobileWebModule.h"
#import "MITMobileServerConfiguration.h"

@implementation MobileWebModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = MobileWebTag;
        self.shortName = @"Mobile Web";
        self.longName = @"MIT Mobile Web";
        self.iconName = @"webmitedu";
    }
    return self;
}

- (void)willAppear {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebGetCurrentServerDomain()]]];
}

@end
