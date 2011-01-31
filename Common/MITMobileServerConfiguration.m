//
//  MITMobileServerConfiguration.m
//

#import "MITMobileServerConfiguration.h"

#define MMW_DEFAULT_SERVER_INDEX 0

NSArray* MITMobileWebGetAPIServerList( void ) {
    static NSMutableArray* array = nil;
    
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
        [array addObject:[NSURL URLWithString:@"http://mobile-stage.mit.edu/api"]];
        
        /* I am basing the below URLs from the behavior between the different
         *  build schemes currently in use. A 'Debug' build may use any
         *  of the URLs but will default to the Dev server. A 'Release' build
         *  can use either the staging or the production server and will
         *  default to the production URL.
         */
#if defined(USE_MOBILE_DEV)
        [array addObject:[NSURL URLWithString:@"http://m.mit.edu/api"]];
        [array insertObject:[NSURL URLWithString:@"http://mobile-dev.mit.edu/api"]
                    atIndex:MMW_DEFAULT_SERVER_INDEX];
#else
        [array insertObject:[NSURL URLWithString:@"http://m.mit.edu/api"]
                    atIndex:MMW_DEFAULT_SERVER_INDEX];
#endif
        
    }
    
    return [[array copy] autorelease];
}


NSURL* MITMobileWebGetDefaultServerURL( void ) {
    return [[[MITMobileWebGetAPIServerList() objectAtIndex:MMW_DEFAULT_SERVER_INDEX] copy] autorelease];
}


BOOL MITMobileWebSetCurrentServerURL(NSURL* serverURL) {
    NSArray *servers = MITMobileWebGetAPIServerList();
    
    if (![servers containsObject:serverURL])
        return NO;
    else {
        [[NSUserDefaults standardUserDefaults] setURL:serverURL forKey:@"api_server"];
        return YES;
    }
}


NSURL* MITMobileWebGetCurrentServerURL( void ) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSURL* server = [defaults URLForKey:@"api_server"];
    NSArray* serverList = MITMobileWebGetAPIServerList();
    
    if ((server == nil) || (![serverList containsObject:server] )) {
        server = MITMobileWebGetDefaultServerURL();
        [defaults setURL:server
                  forKey:@"api_server"];
    }
    
    return server;
}


NSString* MITMobileWebGetCurrentServerDomain( void ) {
    NSURL* server = MITMobileWebGetCurrentServerURL();
    return [server host];
}


MITMobileWebServerType MITMobileWebGetCurrentServerType( void ) {
    NSURL *server = MITMobileWebGetCurrentServerURL();
    NSRange foundRange = NSMakeRange(NSNotFound, 0);
    
    foundRange = [[server host] rangeOfString:@"-dev."];
    if (foundRange.location != NSNotFound) {
        return MITMobileWebDevelopment;
    }
    
    foundRange = [[server host] rangeOfString:@"-stage."];
    if (foundRange.location != NSNotFound) {
        return MITMobileWebStaging;
    }
    
    return MITMobileWebProduction;
}