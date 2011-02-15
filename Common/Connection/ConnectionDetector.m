#import "ConnectionDetector.h"
#import "Reachability.h"
#import "MITMobileServerConfiguration.h"

@implementation ConnectionDetector

+(bool)isConnected {
	if ([[Reachability sharedReachability] internetConnectionStatus] != NotReachable)	// if the internet is reachable
		return true;	// we are connected
	else			// otherwise
		return false;	// we're not connected
}

+(id)sharedConnectionDetector {
	static ConnectionDetector *sharedInstance;
	if (!sharedInstance) {
		sharedInstance = [[ConnectionDetector alloc] init];
	}

	return sharedInstance;
}

-(id)init {
	self = [super init];
	if (self) {
		[[Reachability sharedReachability] setHostName:MITMobileWebGetCurrentServerDomain()];	// when we check for an internet connection, ping our server
	}
	return self;
}

@end
