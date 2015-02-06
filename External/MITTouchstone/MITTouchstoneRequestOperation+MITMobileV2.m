#import <objc/runtime.h>
#import "MITTouchstoneController.h"

#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITMobileServerConfiguration.h"
#import "MITAdditions.h"

static NSString* const MITMobileOperationCommandAssociatedObjectKey = @"MITMobileOperationCommandAssociatedObject";
static NSString* const MITMobileOperationParametersAssociatedObjectKey = @"MITMobileOperationParametersAssociatedObject";

@implementation MITTouchstoneRequestOperation (MITMobileV2)
@dynamic module;
@dynamic command;
@dynamic parameters;

- (NSString*)module
{
    return [self parameters][@"module"];
}

- (NSString*)command
{
    return [self parameters][@"command"];
}

- (NSDictionary*)parameters
{
    return [self.request.URL queryDictionary];
}
@end


@implementation NSURLRequest (MITMobileV2)
+ (NSURLRequest*)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters
{
    return [self requestForModule:module command:command parameters:parameters method:@"GET"];
}

+ (NSURLRequest*)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod
{
    NSParameterAssert(HTTPMethod);

    NSURL *baseURL = MITMobileWebGetCurrentServerURL();
    
    NSString *urlString = [baseURL absoluteString];
    if ([urlString hasSuffix:@"/"] == NO) {
        baseURL = [NSURL URLWithString:[urlString stringByAppendingString:@"/"]];
    }
    
    
    NSMutableArray *queryParameters = [[NSMutableArray alloc] init];
    if (module) {
        NSString *parameterString = [NSString stringWithFormat:@"module=%@",[module stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [queryParameters addObject:parameterString];
    }
    
    if (command) {
        NSString *parameterString = [NSString stringWithFormat:@"command=%@",[command stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [queryParameters addObject:parameterString];
    }
    
    if ([queryParameters count]) {
        NSString *queryString = [queryParameters componentsJoinedByString:@"&"];
        NSString *urlString = [NSString stringWithFormat:@"%@?%@", [baseURL absoluteString], queryString];
        baseURL = [NSURL URLWithString:urlString];
    }
    
    return [self requestWithURL:baseURL parameters:parameters method:HTTPMethod];
}

+ (NSURLRequest*)requestWithURL:(NSURL *)URL parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod
{
    NSMutableArray *urlParameters = [NSMutableArray arrayWithCapacity:[parameters count]];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {
        NSString *encodedName = [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = nil;
        
        if ([value isKindOfClass:[NSData class]]) {
            NSData *data = (NSData*)value;
            encodedValue = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        } else if ([value isKindOfClass:[NSString class]]) {
            encodedValue = (NSString*)[value copy];
        } else if ([value respondsToSelector:@selector(stringValue)]) {
            encodedValue = [value stringValue];
        }
        
        encodedValue = [encodedValue urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
        
        if (encodedValue) {
            [urlParameters addObject:[NSString stringWithFormat:@"%@=%@",encodedName,encodedValue]];
        } else {
            [urlParameters addObject:encodedName];
        }
    }];
    
    
    NSURL *targetURL = URL;
    NSData *requestData = nil;
    if ([urlParameters count]) {
        NSString *paramString = [urlParameters componentsJoinedByString:@"&"];
        
        if ([HTTPMethod caseInsensitiveCompare:@"POST"] == NSOrderedSame) {
            requestData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            NSMutableString *urlString = [NSMutableString stringWithString:[URL absoluteString]];
            
            // Assume that the URL is properly formed. In that case,
            // the parameters should come after the '?' and there shouldn't
            // be any stray '?' characters as they are reserved
            NSRange matchingRange = [urlString rangeOfString:@"?" options:NSBackwardsSearch];
            
            if (matchingRange.location != NSNotFound) {
                if ([urlString hasSuffix:@"?"]) {
                    // Assume the URL is of the format '.../someResource/?...' or '.../someResource?...'
                    [urlString appendFormat:@"%@", paramString];
                } else {
                    // Assume the url is of the format '...?(parameters*)'
                    [urlString appendFormat:@"&%@", paramString];
                }
            } else {
                // Assume the URL is of the format '.../someResource/' or '.../someResource'
                [urlString appendFormat:@"?%@", paramString];
            }
            
            targetURL = [NSURL URLWithString:urlString];
            requestData = nil;
        }
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:targetURL];
    request.HTTPBody = requestData;
    request.HTTPMethod = HTTPMethod;
    
    if ([HTTPMethod caseInsensitiveCompare:@"POST"] == NSOrderedSame) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    
    return request;
}

@end
