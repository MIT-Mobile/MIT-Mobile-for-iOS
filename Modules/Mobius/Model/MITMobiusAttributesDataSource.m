#import "MITMobiusAttributesDataSource.h"
#import "MITCoreData.h"
#import "MITMobiusAttribute.h"
#import "MITMobiusDataSource.h"
#import "MITAdditions.h"

static NSString* const MITMobiusAttributesPathPattern = @"/attribute";

@interface MITMobiusAttributesDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *operationQueue;
@property (nonatomic,strong) NSOperationQueue *completionOperationQueue;
@property (nonatomic,copy) NSString *queryString;
@end

@implementation MITMobiusAttributesDataSource {
    BOOL _requestInProgress;
    NSError *_requestError;
}

@synthesize attributes = _attributes;

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.parentContext = [MITCoreDataController defaultController].mainQueueContext;
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
- (void)attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self _attributes:completion];
    }];
}

- (void)_attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion
{
    if (!_requestInProgress) {
        _requestInProgress = YES;
        self.completionOperationQueue.suspended = YES;
        
        NSURL *serverURL = [MITMobiusDataSource mobiusServerURL];
        NSURL *attributesURL = [NSURL URLWithString:MITMobiusAttributesPathPattern relativeToURL:serverURL];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:attributesURL];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        // Directly using the RestKit mapping operations here because the app
        // is currently not capable of mapping requests from arbirary hosts on a per-request basis.
        // (the current architecture was implemented under the assumption that all communication
        // would be filtered through the MIT Mobile APIs)
        // (bskinner - 2015.04.08)
        RKMapping *mapping = [MITMobiusAttribute objectMapping];
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        
        RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
        
        NSManagedObjectContext *mappingContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:NO];
        requestOperation.managedObjectContext = mappingContext;
        
        RKFetchRequestManagedObjectCache *cache = [[RKFetchRequestManagedObjectCache alloc] init];
        requestOperation.managedObjectCache = cache;
        
        __weak MITMobiusAttributesDataSource *weakSelf = self;
        [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            MITMobiusAttributesDataSource *blockSelf = weakSelf;
            
            if (!blockSelf) {
                return;
            }
            
            blockSelf->_requestInProgress = NO;
            blockSelf.lastUpdated = [NSDate date];
            [blockSelf.managedObjectContext performBlock:^{
                NSArray *attributes = [blockSelf.managedObjectContext transferManagedObjects:[mappingResult array]];
                
#warning Filtering out the raw text widget types for now
                blockSelf->_attributes = [attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.widgetType != text"]];
                blockSelf.completionOperationQueue.suspended = NO;
            }];
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            MITMobiusAttributesDataSource *blockSelf = weakSelf;
            
            if (!blockSelf) {
                return;
            } else {
                blockSelf.completionOperationQueue.suspended = NO;
                blockSelf->_requestInProgress = NO;
                blockSelf->_requestError = error;
                blockSelf->_attributes = nil;
                
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
    
    __weak MITMobiusAttributesDataSource *weakSelf = self;
    [self.completionOperationQueue addOperationWithBlock:^{
        MITMobiusAttributesDataSource *blockSelf = weakSelf;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (completion) {
                completion(blockSelf,_requestError);
            }
        }];
    }];
}

@end
