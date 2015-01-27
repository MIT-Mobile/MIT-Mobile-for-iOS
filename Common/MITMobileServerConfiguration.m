//
//  MITMobileServerConfiguration.m
//

#import <Foundation/Foundation.h>
#import "MITMobileServerConfiguration.h"

static NSString * const MobileAPIServers[] = {@"https://m.mit.edu/api", @"https://mobile-dev.mit.edu/api", @"https://mobile-stage.mit.edu/api", nil};

#if defined(TESTFLIGHT)
NSUInteger const MITMobileServerConfigurationDefaultIndex = 0;
#elif defined(DEBUG)
NSUInteger const MITMobileServerConfigurationDefaultIndex = 1;
#else
NSUInteger const MITMobileServerConfigurationDefaultIndex = 0;
#endif

NSArray* MITMobileWebGetAPIServerList( void ) {
    static NSMutableArray* array = nil;
    
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
        for (int i = 0; MobileAPIServers[i] != nil; ++i) {
            NSURL *url = [NSURL URLWithString:MobileAPIServers[i]];
            if (url != nil) {
                DDLogCVerbose( @"Got %@", [url absoluteString]);
                [array addObject:url];
            } else {
                DDLogCError(@"API URL '%@' is malformed", url);
            }
        }
        
        NSCAssert(([array count] >= 1),@"There must be at least 1 valid API server");
    }
    
    return [[array copy] autorelease];
}


NSURL* MITMobileWebGetDefaultServerURL( void ) {
    return [[[MITMobileWebGetAPIServerList() objectAtIndex:MITMobileServerConfigurationDefaultIndex] copy] autorelease];
}


BOOL MITMobileWebSetCurrentServerURL(NSURL* serverURL) {
    NSArray *servers = MITMobileWebGetAPIServerList();
    
    if (![servers containsObject:serverURL])
        return NO;
    else {
        [[NSUserDefaults standardUserDefaults] setURL:serverURL forKey:@"api_server"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
}


NSURL* MITMobileWebGetCurrentServerURL( void ) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSURL* server = [defaults URLForKey:@"api_server"];
    NSArray* serverList = MITMobileWebGetAPIServerList();
    
    if ((server == nil) || (![serverList containsObject:server] )) {
        server = MITMobileWebGetDefaultServerURL();
        MITMobileWebSetCurrentServerURL(server);
    }
    
    return server;
}


NSString* MITMobileWebGetCurrentServerDomain( void ) {
    NSURL* server = MITMobileWebGetCurrentServerURL();
    return [server host];
}


MITMobileWebServerType MITMobileWebGetCurrentServerType( void ) {
    NSURL *server = MITMobileWebGetCurrentServerURL();
    NSRange foundRange = [[server host] rangeOfString:@"-dev."];

    if (foundRange.location != NSNotFound) {
        return MITMobileWebDevelopment;
    }
    
    foundRange = [[server host] rangeOfString:@"-stage."];
    if (foundRange.location != NSNotFound) {
        return MITMobileWebStaging;
    }
    
    return MITMobileWebProduction;
}