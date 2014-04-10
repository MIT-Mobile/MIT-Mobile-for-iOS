#import "MITTouchstoneRequestOperation.h"

@compatibility_alias MobileRequestOperation MITTouchstoneRequestOperation;

@interface MITTouchstoneRequestOperation ()
@property (nonatomic,copy) NSString *command;
@property (nonatomic,copy) NSDictionary *parameters;
@end

@interface MITTouchstoneRequestOperation (LegacyCompatibility)
+ (id)operationWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
+ (id)operationWithURL:(NSURL*)requestURL parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
+ (NSOperationQueue*)defaultQueue DEPRECATED_ATTRIBUTE;

- (id)initWithModule:(NSString*)aModule command:(NSString*)theCommand parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;
- (id)initWithURL:(NSURL*)requestURL parameters:(NSDictionary*)params DEPRECATED_ATTRIBUTE;

- (void)setCompleteBlock:(void (^)(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error))block DEPRECATED_ATTRIBUTE;

- (void)migrateLegacyStoredCredentialsIfNeeded;
@end
