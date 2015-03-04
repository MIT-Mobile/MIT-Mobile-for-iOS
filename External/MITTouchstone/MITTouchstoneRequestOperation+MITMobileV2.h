#import "MITTouchstoneRequestOperation.h"

@interface NSURLRequest (MITMobileV2)
// Defaults to using "GET" as the method
+ (NSURLRequest*)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters;
+ (NSURLRequest*)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod;
+ (NSURLRequest*)requestWithURL:(NSURL *)URL parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod;
@end

@interface MITTouchstoneRequestOperation (MITMobileV2)
@property (nonatomic,readonly) NSString *module;
@property (nonatomic,readonly) NSString *command;
@property (nonatomic,readonly) NSDictionary *parameters;
@end
