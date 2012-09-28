#import "MFMailComposeViewController+RFC2368.h"

@implementation MFMailComposeViewController (RFC2368)
- (NSArray*)scanAddressesFromString:(NSString*)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSMutableArray *addresses = [NSMutableArray array];
    
    while (![scanner isAtEnd]) {
        NSString *address = nil;
        [scanner scanUpToString:@"," intoString:&address];
        [scanner scanString:@"," intoString:NULL];
        [addresses addObject:[address stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    
    return [NSArray arrayWithArray:addresses];
}

- (NSArray*)scanToFieldWithScanner:(NSScanner*)scanner {
    NSString *addresses = nil;
    BOOL result = [scanner scanUpToString:@"?"
                                intoString:&addresses];
    if (!result) {
        return nil;
    }

    return [self scanAddressesFromString:addresses];
}

- (NSDictionary*)scanHeadersWithScanner:(NSScanner*)scanner {
    NSMutableDictionary *fields = [NSMutableDictionary dictionary];
    NSArray *addressHeaders = [NSArray arrayWithObjects:@"to",@"cc",@"bcc",nil];
    
    if (![scanner isAtEnd]) {
        BOOL scanResult = YES;
        scanResult = [scanner scanString:@"?" intoString:nil];
        while (scanResult && ![scanner isAtEnd]) {
            NSString *hname = nil;
            NSString *hvalue = nil;
            
            scanResult = [scanner scanUpToString:@"=" intoString:&hname];
            [scanner scanString:@"=" intoString:NULL];
            scanResult = scanResult && [scanner scanUpToString:@"&" intoString:&hvalue];
            [scanner scanString:@"&" intoString:NULL];
            
            if (hname && hvalue) {
                if ([addressHeaders containsObject:[hname lowercaseString]]) {
                    [fields setObject:[self scanAddressesFromString:hvalue]
                               forKey:[hname lowercaseString]];
                } else {
                    [fields setObject:[hvalue stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
                               forKey:[hname lowercaseString]];
                }
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:fields];
}
    
    
- (NSDictionary*)scanURL:(NSURL*)url {
    NSMutableDictionary *fields = nil;
    NSScanner *scanner = [NSScanner scannerWithString:[url absoluteString]];
    [scanner setCaseSensitive:NO];
    
    if (![scanner scanString:@"mailto:" intoString:NULL]) {
        WLog(@"URL '%@' is malformed", [url absoluteString]);
        fields = nil;
    } else if (![scanner isAtEnd]) {
        // Don't care if this fails. Some malformed mailto urls
        // are used in the app and this should (slightly) clean
        // it up.
        [scanner scanString:@"//" intoString:NULL];
        NSArray *toField = [self scanToFieldWithScanner:scanner];
        fields = [NSMutableDictionary dictionaryWithDictionary:[self scanHeadersWithScanner:scanner]];
        
        if ([fields objectForKey:@"to"]) {
            [fields setObject:[toField arrayByAddingObjectsFromArray:[fields objectForKey:@"to"]]
                       forKey:@"to"];
        } else {
            [fields setObject:toField
                       forKey:@"to"];
        }
    } else {
        fields = nil;
    }
    
    return [NSDictionary dictionaryWithDictionary:fields];
} 

- (id)initWithMailToURL:(NSURL*)mailtoUrl
{
    self = [super init];
    
    if (self) {
        DLog(@"Processing URL: %@",[mailtoUrl absoluteString]);
        NSDictionary *fields = [self scanURL:mailtoUrl];
        
        if ([fields objectForKey:@"to"]) {
            [self setToRecipients:[fields objectForKey:@"to"]];
        }
        
        if ([fields objectForKey:@"cc"]) {
            [self setCcRecipients:[fields objectForKey:@"cc"]];
        }
        
        if ([fields objectForKey:@"bcc"]) {
            [self setBccRecipients:[fields objectForKey:@"bcc"]];
        }
        
        if ([fields objectForKey:@"subject"]) {
            [self setSubject:[fields objectForKey:@"subject"]];
        }
        
        if ([fields objectForKey:@"body"]) {
            [self setMessageBody:[fields objectForKey:@"body"]
                          isHTML:NO];
        }
    }
    
    return self;
}
@end
