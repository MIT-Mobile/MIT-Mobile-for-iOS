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

- (NSArray*)fetchRequestForURLBlocks
{
    // If not overridden, assume there is only one fetch request and return that in a block in an array
    NSFetchRequest *(^fetchRequestBlock)(NSURL *URL) = ^NSFetchRequest *(NSURL *URL) {
        return [self fetchRequestForURL:URL];
    };
    return @[fetchRequestBlock];
}

@end
