#import "MITTouchstoneNetworkIdentityProvider.h"

@implementation MITTouchstoneNetworkIdentityProvider

- (NSString*)name
{
    return @"MIT";
}

- (NSURL*)URL
{
    return [NSURL URLWithString:@"https://idp.touchstonenetwork.net/idp/profile/SAML2/SOAP/ECP"];
}

- (NSURLProtectionSpace*)protectionSpace
{
    NSURL *url = self.URL;
    return [[NSURLProtectionSpace alloc] initWithHost:[url host]
                                                 port:0
                                             protocol:[url scheme]
                                                realm:nil
                                 authenticationMethod:NSURLAuthenticationMethodDefault];
}

- (BOOL)canAuthenticateForUser:(NSString*)username
{
    if (![username length]) {
        return NO;
    }
    
    NSRange domainPartRange = [username rangeOfString:@"@" options:NSBackwardsSearch];
    
    NSString *domainPart = nil;
    if (domainPartRange.location != NSNotFound) {
        domainPartRange.length = [username length] - domainPartRange.location;
        domainPart = [[[username substringWithRange:domainPartRange] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if ([domainPart length]) {
        return YES;
    } else {
        return NO;
    }
}

@end
