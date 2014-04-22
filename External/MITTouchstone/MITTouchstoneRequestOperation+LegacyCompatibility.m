#import <objc/runtime.h>
#import "MITTouchstoneController.h"

#import "MITTouchstoneRequestOperation+LegacyCompatibility.h"
#import "MITMobileServerConfiguration.h"
#import "MobileKeychainServices.h"
#import "MITAdditions.h"

static NSString* const MITMobileOperationCommandAssociatedObjectKey = @"MITMobileOperationCommandAssociatedObject";
static NSString* const MITMobileOperationParametersAssociatedObjectKey = @"MITMobileOperationParametersAssociatedObject";

@implementation MITTouchstoneRequestOperation (LegacyCompatibility)
+ (id)operationWithURL:(NSURL *)requestURL parameters:(NSDictionary *)params
{
    return [[self alloc] initWithURL:requestURL
                          parameters:params];
}

+ (id)operationWithModule:(NSString *)aModule command:(NSString *)theCommand parameters:(NSDictionary *)params
{
    return [[self alloc] initWithModule:aModule
                                command:theCommand
                             parameters:params];
}

+ (NSOperationQueue*)defaultQueue
{
    return [NSOperationQueue mainQueue];
}

- (id)initWithModule:(NSString *)aModule command:(NSString *)theCommand parameters:(NSDictionary *)params
{
    NSURLRequest *urlRequest = [NSURLRequest requestForModule:aModule command:theCommand parameters:params method:@"GET"];
    
    return [self initWithRequest:urlRequest];
}

- (id)initWithURL:(NSURL *)requestURL parameters:(NSDictionary *)params
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:requestURL parameters:params method:@"GET"];
    return [self initWithRequest:urlRequest];
}

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

- (void)setCompleteBlock:(void (^)(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error))block
{
    [self setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(operation,responseObject,operation.response.MIMEType,nil);
            }
        }];
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(operation,nil,nil,error);
            }
        }];
    }];
}

@end


@implementation NSURLRequest (LegacyCompatibiltiy)
+ (instancetype)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod
{
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

+ (instancetype)requestWithURL:(NSURL *)URL parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod
{
    NSMutableArray *urlParameters = [NSMutableArray arrayWithCapacity:[parameters count]];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {
        NSString *encodedName = [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = nil;
        
        if ([value isKindOfClass:[NSString class]]) {
            encodedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else if ([value respondsToSelector:@selector(stringValue)]) {
            encodedValue = [[value stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
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
    
    return request;
}

@end
