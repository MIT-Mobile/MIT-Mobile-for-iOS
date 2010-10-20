#import "ConnectionDetector.h"
#import "Reachability.h"

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
	if (self=[super init]) {
		[[Reachability sharedReachability] setHostName:MITMobileWebDomainString];	// when we check for an internet connection, ping our server
	}
	return self;
}

@end
