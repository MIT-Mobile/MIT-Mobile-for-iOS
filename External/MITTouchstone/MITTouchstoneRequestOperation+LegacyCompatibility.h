#import "MITTouchstoneRequestOperation.h"

@compatibility_alias MobileRequestOperation MITTouchstoneRequestOperation;

@interface MITTouchstoneRequestOperation ()
@property (nonatomic,readonly) NSString *module;
@property (nonatomic,readonly) NSString *command;
@property (nonatomic,readonly) NSDictionary *parameters;
@end

@interface NSURLRequest (LegacyCompatibiltiy)
+ (instancetype)requestForModule:(NSString*)module command:(NSString*)command parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod;
+ (instancetype)requestWithURL:(NSURL *)URL parameters:(NSDictionary*)parameters method:(NSString*)HTTPMethod;
@end

@interface MITTouchstoneRequestOperation (LegacyCompatibility)
+ (id)operationWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
+ (id)operationWithURL:(NSURL*)requestURL parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
+ (NSOperationQueue*)defaultQueue DEPRECATED_ATTRIBUTE;

- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
- (id)initWithURL:(NSURL*)requestURL parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;

- (void)setCompleteBlock:(void (^)(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error))block DEPRECATED_ATTRIBUTE;
@end
