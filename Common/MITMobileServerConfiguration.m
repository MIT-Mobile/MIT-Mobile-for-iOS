//
//  MITMobileServerConfiguration.m
//

#import <Foundation/Foundation.h>
#import "MITMobileServerConfiguration.h"
#import "Secret.h"

#ifndef MobileAPI_DefaultServerIndex
    #define MobileAPI_DefaultServerIndex 0
#endif

NSArray* MITMobileWebGetAPIServerList( void ) {
    static NSMutableArray* array = nil;
    
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
        for (int i = 0; MobileAPIServers[i] != nil; ++i) {
            NSURL *url = [NSURL URLWithString:MobileAPIServers[i]];
            if (url != nil) {
                DLog( @"Got %@", [url absoluteString]);
                [array addObject:url];
            } else {
                ELog(@"API URL '%@' is malformed", url);
            }
        }
        
        NSCAssert(([array count] >= 1),@"There must be at least 1 valid API server");
    }
    
    return [[array copy] autorelease];
}


NSURL* MITMobileWebGetDefaultServerURL( void ) {
    return [[[MITMobileWebGetAPIServerList() objectAtIndex:MobileAPI_DefaultServerIndex] copy] autorelease];
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