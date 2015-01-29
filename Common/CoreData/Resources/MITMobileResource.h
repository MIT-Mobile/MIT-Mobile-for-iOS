#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@class MITMappingSet;
@class RKMapping;

typedef void (^MITMobileResult)(NSArray *objects, NSError *error);

@interface MITMobileResource : NSObject
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *pathPattern;
@property (nonatomic,readonly) RKRequestMethod requestMethods;

@property (nonatomic,strong) NSDate *refreshedDate;
@property (nonatomic) NSTimeInterval expiryInterval;

// Shorthand for creating a resource with a single mapping. The RKRequestMethod
// can be a bitmask and all the set methods will be assigned
+ (instancetype)resourceWithName:(NSString*)name pathPattern:(NSString*)path mapping:(RKMapping*)mapping method:(RKRequestMethod)method;
- (instancetype)initWithName:(NSString*)name pathPattern:(NSString*)pathPattern;

- (void)loadMappings;
- (void)addMapping:(RKMapping*)mapping atKeyPath:(NSString*)keyPath forRequestMethod:(RKRequestMethod)method;
- (void)enumerateMappingsByRequestMethodUsingBlock:(void (^)(RKRequestMethod method, NSDictionary *mappings))block;
- (void)enumerateMappingsForRequestMethod:(RKRequestMethod)method usingBlock:(void (^)(NSString *keyPath, RKMapping *mapping))block;
@end
