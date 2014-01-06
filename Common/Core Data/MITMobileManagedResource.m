#import "MITMobileManagedResource.h"

@implementation MITMobileManagedResource
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"failed to call designated initializer. Invoke -initWithName:pathPattern:managedObjectModel: instead."
                                 userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name pathPattern:(NSString *)pathPattern
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"failed to call designated initializer. Invoke -initWithName:pathPattern:managedObjectModel: instead."
                                 userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name pathPattern:(NSString *)pathPattern managedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    NSParameterAssert(managedObjectModel);
    
    self = [super initWithName:name pathPattern:pathPattern];
    if (self) {
        _managedObjectModel = managedObjectModel;
    }
    
    return self;
}

- (NSFetchRequest*)fetchRequestForURL:(NSURL *)url
{
    return nil;
}
@end
