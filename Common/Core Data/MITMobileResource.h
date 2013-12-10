#import <Foundation/Foundation.h>

// Order is important here. If the CoreData headers
// are not imported *before* the RestKit headers,
// the CoreData portions will be skipped by the preprocessor
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@class MITMappingSet;
@class RKMapping;

@interface MITMobileResource : NSObject
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *pathPattern;
@property (nonatomic,strong) NSFetchRequest* (^fetchGenerator)(NSURL *url);

// Shorthand for creating a resource with a single mapping. The RKRequestMethod
// can be a bitmask and all the set methods will be assigned
+ (instancetype)resourceWithName:(NSString*)name pathPattern:(NSString*)path mapping:(RKMapping*)mapping method:(RKRequestMethod)method;
- (instancetype)initWithName:(NSString*)name pathPattern:(NSString*)pathPattern;

- (void)addMapping:(RKMapping*)mapping atKeyPath:(NSString*)keyPath forRequestMethod:(RKRequestMethod)method;
- (void)enumerateMappingsByRequestMethodUsingBlock:(void (^)(RKRequestMethod method, NSDictionary *mappings))block;
- (void)enumerateMappingsForRequestMethod:(RKRequestMethod)method usingBlock:(void (^)(NSString *keyPath, RKMapping *mapping))block;
@end
