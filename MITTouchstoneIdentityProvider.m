#import "MITTouchstoneIdentityProvider.h"

@implementation MITTouchstoneIdentityProvider

- (NSString*)name
{
    return @"MIT";
}

- (NSURL*)URL
{
    return [NSURL URLWithString:@"https://idp.mit.edu/idp/profile/SAML2/SOAP/ECP"];
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
    
    if (!domainPart || [domainPart hasSuffix:@"@mit.edu"]) {
        return YES;
    } else {
        return NO;
    }
}


- (NSString*)localUserForUser:(NSString*)user
{
    if (!user) {
        return nil;
    }

    NSRange domainPartRange = [user rangeOfString:@"@" options:NSBackwardsSearch];

    NSString *userPart = nil;
    NSString *domainPart = nil;
    if (domainPartRange.location != NSNotFound) {
        domainPartRange.length = [user length] - domainPartRange.location;
        domainPart = [[[user substringWithRange:domainPartRange] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        userPart = [user substringWithRange:NSMakeRange(0, domainPartRange.location)];
    } else {
        userPart = user;
    }

    if (!domainPart || [domainPart hasSuffix:@"@mit.edu"]) {
        return userPart;
    } else {
        return nil;
    }
}

@end
