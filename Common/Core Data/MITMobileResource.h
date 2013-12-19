#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h> // Must be imported before RestKit 
#import <RestKit/RestKit.h>

@class MITMappingSet;
@class RKMapping;

@interface MITMobileResource : NSObject
@property (nonatomic,readonly) NSString *pathPattern;
@property (nonatomic,readonly) RKRequestMethod requestMethods;

@property (nonatomic,strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic,strong) NSDate *refreshedDate;
@property (nonatomic) NSTimeInterval expiryInterval;

// Shorthand for creating a resource with a single mapping. The RKRequestMethod
// can be a bitmask and all the set methods will be assigned
+ (instancetype)resourceWithPathPattern:(NSString*)path mapping:(RKMapping*)mapping method:(RKRequestMethod)method;
- (instancetype)initWithPathPattern:(NSString*)pathPattern;

- (void)loadMappings;
- (void)addMapping:(RKMapping*)mapping atKeyPath:(NSString*)keyPath forRequestMethod:(RKRequestMethod)method;
- (void)enumerateMappingsByRequestMethodUsingBlock:(void (^)(RKRequestMethod method, NSDictionary *mappings))block;
- (void)enumerateMappingsForRequestMethod:(RKRequestMethod)method usingBlock:(void (^)(NSString *keyPath, RKMapping *mapping))block;

- (NSFetchRequest*)fetchRequestForURL:(NSURL*)url;
@end
