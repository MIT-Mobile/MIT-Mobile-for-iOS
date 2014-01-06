#import "MITMobileResource.h"

static inline void MITMobileEnumerateRequestMethodsUsingBlock(RKRequestMethod method, void (^block)(RKRequestMethod method))
{
    NSCParameterAssert(block);

    NSArray *methods = @[@(RKRequestMethodGET),
                         @(RKRequestMethodPOST),
                         @(RKRequestMethodPUT),
                         @(RKRequestMethodDELETE),
                         @(RKRequestMethodHEAD),
                         @(RKRequestMethodPATCH),
                         @(RKRequestMethodOPTIONS)];
    [methods enumerateObjectsUsingBlock:^(NSNumber *requestMethod, NSUInteger idx, BOOL *stop) {
        RKRequestMethod desiredMethod = [requestMethod integerValue];

        if (desiredMethod & method) {
            block(desiredMethod);
        }
    }];
}

#pragma mark -
@interface MITMobileResource ()
@property (nonatomic,strong) NSMutableDictionary *registeredMappings;
@end

@implementation MITMobileResource

+ (instancetype)resourceWithName:(NSString*)name
                     pathPattern:(NSString*)path
                                mapping:(RKMapping*)mapping
                                 method:(RKRequestMethod)method
{
    MITMobileResource *resource = [[MITMobileResource alloc] initWithName:name pathPattern:path];
    [resource addMapping:mapping
               atKeyPath:nil
        forRequestMethod:method];
    return resource;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"failed to call designated initializer. Invoke -initWithName:pathPattern: instead"
                                 userInfo:nil];
}

- (instancetype)initWithName:(NSString*)name pathPattern:(NSString *)pathPattern
{
    NSParameterAssert(pathPattern);

    self = [super init];
    if (self) {
        _pathPattern = [pathPattern copy];
        _name = [name copy];
    }

    return self;
}

- (NSMutableDictionary*)registeredMappings
{
    if (!_registeredMappings) {
        [self loadMappings];
    }

    return _registeredMappings;
}

- (void)loadMappings
{
    return;
}

- (void)addMapping:(RKMapping*)mapping atKeyPath:(NSString*)keyPath forRequestMethod:(RKRequestMethod)method
{
    NSParameterAssert(mapping);

    if (_registeredMappings == nil) {
        _registeredMappings = [[NSMutableDictionary alloc] init];
    }

    MITMobileEnumerateRequestMethodsUsingBlock(method, ^(RKRequestMethod requestMethod) {
        NSString *key = RKStringFromRequestMethod(requestMethod);

        NSMutableDictionary *mappings = self.registeredMappings[key];
        NSAssert(mappings || !keyPath,@"unable to set mapping for keypath '%@' until a mapping for the nil keypath is added",keyPath);
        NSAssert(!mappings || keyPath,@"a mapping for the nil keypath for method '%@' already exists",key);

        if (!mappings) {
            mappings = [[NSMutableDictionary alloc] init];
            mappings[[NSNull null]] = mapping;
            self.registeredMappings[key] = mappings;
        } else {
            mappings[key] = mapping;
        }
    });
}

- (void)enumerateMappingsByRequestMethodUsingBlock:(void (^)(RKRequestMethod method, NSDictionary *mappings))block
{
    NSParameterAssert(block);

    [self.registeredMappings enumerateKeysAndObjectsUsingBlock:^(NSString *methodName, NSDictionary *mappings, BOOL *stop) {
        RKRequestMethod method = RKRequestMethodFromString(methodName);
        block(method,mappings);
    }];
}

- (void)enumerateMappingsForRequestMethod:(RKRequestMethod)method usingBlock:(void (^)(NSString *keyPath, RKMapping *mapping))block
{
    NSParameterAssert(block);

    MITMobileEnumerateRequestMethodsUsingBlock(method, ^(RKRequestMethod method) {
        NSString *key = RKStringFromRequestMethod(method);
        NSDictionary *mappings = self.registeredMappings[key];

        NSArray *keyPaths = [[mappings allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNull *nullObj = [NSNull null];

            if ([obj1 isEqual:nullObj] || [obj2 isEqual:nullObj]) {
                if ([obj1 isEqual:nullObj] && [obj2 isEqual:nullObj]) {
                    return NSOrderedSame;
                } else if ([obj1 isEqual:nullObj]) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedAscending;
                }
            } else {
                NSString *key1 = (NSString*)obj1;
                NSString *key2 = (NSString*)obj2;
                return [key1 caseInsensitiveCompare:key2];
            }
        }];

        [keyPaths enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL *stop) {
            block(keyPath,mappings[keyPath]);
        }];
    });
}

- (RKRequestMethod)requestMethods
{
    __block RKRequestMethod methods = 0;
    [self.registeredMappings enumerateKeysAndObjectsUsingBlock:^(NSString *method, id obj, BOOL *stop) {
        RKRequestMethod requestMethod = RKRequestMethodFromString(method);
        methods |= requestMethod;
    }];

    return methods;
}


#pragma mark - Dynamic Properties
@end
