#import "MITTouchstoneRequestOperation+MITMobileV3.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITMobileServerConfiguration.h"

@implementation MITTouchstoneRequestOperation (MITMobileV3)

// This replaces the V2 requestForModule with the V3 api endpoints (i.e. uses a URL without the module as a parameter, but as part of the base URL)
+ (NSURLRequest*)requestForEndpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters andRequestMethod:(NSString *)requestMethod
{
    NSURL *baseURL = [[NSURL URLWithString:@"/"
                               relativeToURL:MITMobileWebGetCurrentServerURL()] absoluteURL];
    
    NSString *urlString = [[baseURL absoluteString] stringByAppendingString:@"apis/"];;
    urlString = [urlString stringByAppendingString:endpoint];
    baseURL = [NSURL URLWithString:urlString];
  
    return [NSURLRequest requestWithURL:baseURL parameters:parameters method:requestMethod];
}

@end