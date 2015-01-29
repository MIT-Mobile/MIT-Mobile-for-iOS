#import "ConnectionDetector.h"
#import "Reachability.h"
#import "MITMobileServerConfiguration.h"

@implementation ConnectionDetector

@synthesize reachability = _reachability;

// TODO: We should be making use of Reachability's notification 
// system to intelligently retry connections.

+ (BOOL)isConnected {
    Reachability *reachability = [[self sharedConnectionDetector] reachability];
	if ([reachability currentReachabilityStatus] != NotReachable) {	
                        // if the internet is reachable
		return true;	// we are connected
    } else {			// otherwise
		return false;	// we're not connected
    }
}

+ (id)sharedConnectionDetector {
	static ConnectionDetector *sharedInstance;
	if (!sharedInstance) {
		sharedInstance = [[ConnectionDetector alloc] init];
	}

	return sharedInstance;
}

- (id)init {
	self = [super init];
	if (self) {
        // use our api server to check for a connection
		_reachability = [Reachability reachabilityWithHostName:MITMobileWebGetCurrentServerDomain()];
	}
	return self;
}

@end
