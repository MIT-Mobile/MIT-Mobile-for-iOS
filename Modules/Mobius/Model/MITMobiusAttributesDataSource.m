#import "MITMobiusAttributesDataSource.h"
#import "MITCoreData.h"
#import "MITMobiusResourceAttribute.h"
#import "MITMobiusDataSource.h"
#import "MITAdditions.h"

static NSString* const MITMobiusAttributesPathPattern = @"/attribute";

@interface MITMobiusAttributesDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *operationQueue;
@property (nonatomic,strong) NSOperationQueue *completionOperationQueue;
@property (nonatomic,copy) NSArray *objectIdentifiers;
@property (nonatomic,copy) NSString *queryString;
@end

@implementation MITMobiusAttributesDataSource {
    BOOL _requestInProgress;
    NSError *_requestError;
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
        _operationQueue.maxConcurrentOperationCount = 1;

        _completionOperationQueue = [[NSOperationQueue alloc] init];
        _completionOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }

    return self;
}


#pragma mark Public Interface Methods
- (NSArray*)attributesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext error:(NSError**)error
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMobiusResourceAttribute entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"ANY self.identifier IN %@",self.objectIdentifiers];

    NSError *fetchError = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];

    if (!fetchedObjects) {
        DDLogWarn(@"Fetch of %@ objects failed: %@", [MITMobiusResourceAttribute entityName], fetchError);

        if (error) {
            (*error) = fetchError;
        }
    } else {
        NSArray *sortedObjects = [fetchedObjects sortedArrayUsingComparator:^NSComparisonResult(MITMobiusResourceAttribute *attribute1, MITMobiusResourceAttribute *attribute2) {

            NSNumber *attributeIndex1 = @([self.objectIdentifiers indexOfObject:attribute1.identifier]);
            NSNumber *attributeIndex2 = @([self.objectIdentifiers indexOfObject:attribute2.identifier]);

            return [attributeIndex1 compare:attributeIndex2];
        }];

        fetchedObjects = sortedObjects;
    }

    return fetchedObjects;
}

- (void)attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _attributes:completion];
    }];
}

- (void)_attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion
{
    if (_requestInProgress) {
        __weak MITMobiusAttributesDataSource *weakSelf = self;
        [self.operationQueue addOperationWithBlock:^{
            MITMobiusAttributesDataSource *blockSelf = weakSelf;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (completion) {
                    completion(blockSelf,_requestError);
                }
            }];
        }];
    } else {
        self.completionOperationQueue.suspended = YES;

        NSURL *serverURL = [MITMobiusDataSource mobiusServerURL];
        NSURL *attributesURL = [NSURL URLWithString:MITMobiusAttributesPathPattern relativeToURL:serverURL];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:attributesURL];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPMethod = @"GET";
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        RKMapping *mapping = [MITMobiusResourceAttribute objectMapping];
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

        RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
        requestOperation.managedObjectContext = self.managedObjectContext;

        RKFetchRequestManagedObjectCache *cache = [[RKFetchRequestManagedObjectCache alloc] init];
        requestOperation.managedObjectCache = cache;

        __weak MITMobiusAttributesDataSource *weakSelf = self;
        [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            MITMobiusAttributesDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
            }

            NSManagedObjectContext *context = blockSelf.managedObjectContext;
            [context performBlock:^{
                blockSelf.lastUpdated = [NSDate date];
                blockSelf.objectIdentifiers = [[mappingResult array] mapObjectsUsingBlock:^NSString*(MITMobiusResourceAttribute *attribute, NSUInteger idx) {
                    Class attributeClass = [MITMobiusResourceAttribute class];
                    NSAssert([attribute isKindOfClass:attributeClass], @"attribute is kind of %@, expected %@", NSStringFromClass([attribute class]), NSStringFromClass(attributeClass));
                    return attribute.identifier;
                }];

                blockSelf.completionOperationQueue.suspended = NO;
            }];
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            MITMobiusAttributesDataSource *blockSelf = weakSelf;
            blockSelf.completionOperationQueue.suspended = NO;

            if (!blockSelf) {
                return;
            } else {
                blockSelf->_requestError = error;
                DDLogError(@"failed to request Mobius resources: %@",error);
                [self.completionOperationQueue addOperationWithBlock:^{
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (completion) {
                            completion(blockSelf,error);
                        }
                    }];
                }];

                blockSelf.completionOperationQueue.suspended = NO;
            }
        }];

        [self.operationQueue addOperation:requestOperation];
    }
}

@end
