#import "MITMobiusAttributesDataSource.h"
#import "MITCoreData.h"

static NSString* const MITMobiusResourcePathPattern = @"attribute";

@interface MITMobiusAttributesDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *operationQueue;
@property (nonatomic,copy) NSArray *objectIdentifier;
@property (nonatomic,copy) NSString *queryString;
@end

@implementation MITMobiusAttributesDataSource {
    BOOL _requestInProgress;
}

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSParameterAssert(managedObjectContext);

    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
        _operationQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}


#pragma mark Public Interface Methods
- (NSArray*)attributesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{

}

- (void)attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion
{
    if (_requestInProgress) {
        [self.operationQueue addOperationWithBlock:^{
            <#code#>
        }];
    }
}

@end
