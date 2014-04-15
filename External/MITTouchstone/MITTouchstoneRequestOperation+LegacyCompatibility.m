#import <objc/runtime.h>
#import "MITTouchstoneController.h"

#import "MITTouchstoneRequestOperation+LegacyCompatibility.h"
#import "MITMobileServerConfiguration.h"
#import "MobileKeychainServices.h"

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
    NSURL *baseURL = MITMobileWebGetCurrentServerURL();

    if ([[baseURL absoluteString] hasSuffix:@"/"] == NO) {
        baseURL = [NSURL URLWithString:[[baseURL absoluteString] stringByAppendingString:@"/"]];
    }

    if ([aModule length] || [theCommand length]) {
        NSMutableArray *coreParams = [NSMutableArray array];

        if ([aModule length]) {
            [coreParams addObject:[NSString stringWithFormat:@"module=%@",[aModule stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }

        if ([theCommand length]) {
            [coreParams addObject:[NSString stringWithFormat:@"command=%@",[theCommand stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }

        NSString *urlString = [NSString stringWithFormat:@"%@?%@", [baseURL absoluteString], [coreParams componentsJoinedByString:@"&"]];
        baseURL = [NSURL URLWithString:urlString];
        NSLog(@"Initialized module request with URL '%@'", urlString);
    }

    return [self initWithURL:baseURL parameters:params];
}

- (id)initWithURL:(NSURL *)requestURL parameters:(NSDictionary *)params
{
    NSURLRequest *urlRequest = [self urlRequestWithURL:requestURL parameters:params];
    return [self initWithRequest:urlRequest];
}

- (void)setCommand:(NSString*)command
{
    if (![self.command isEqualToString:command]) {
        objc_setAssociatedObject(self, (__bridge const void*)MITMobileOperationCommandAssociatedObjectKey, command, OBJC_ASSOCIATION_COPY);
    }
}

- (NSString*)command
{
    return objc_getAssociatedObject(self, (__bridge const void*)MITMobileOperationCommandAssociatedObjectKey);
}

- (void)setParameters:(NSDictionary*)parameters
{
    if (![self.parameters isEqual:parameters]) {
        objc_setAssociatedObject(self, (__bridge const void*)MITMobileOperationParametersAssociatedObjectKey, parameters, OBJC_ASSOCIATION_COPY);
    }
}

- (NSDictionary*)parameters
{
    return objc_getAssociatedObject(self, (__bridge const void*)MITMobileOperationParametersAssociatedObjectKey);
}

- (NSURLRequest *)urlRequestWithURL:(NSURL*)URL parameters:(NSDictionary*)parameters
{
    NSMutableString *urlString = [NSMutableString stringWithString:[URL absoluteString]];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:[parameters count]];

    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *name, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]]) {
            [params addObject:[NSString stringWithFormat:@"%@=%@",[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                                  [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        } else if ([value respondsToSelector:@selector(stringValue)]) {
            [params addObject:[NSString stringWithFormat:@"%@=%@",[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                                  [[value stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }
    }];

    if ([params count]) {
        NSString *paramString = [params componentsJoinedByString:@"&"];

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
    }

    return [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
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
