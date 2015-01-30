#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

#import "MITMartyResourceDataSource.h"
#import "MITCoreData.h"
#import "CoreData+MITAdditions.h"
#import "MITAdditions.h"
#import "MITMartyResource.h"

static NSString* const MITMartyDefaultServer = @"https://kairos-dev.mit.edu";
static NSString* const MITMartyResourcePathPattern = @"resource";

@interface MITMartyResourceDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *mappingOperationQueue;
@property (copy) NSArray *resourceObjectIdentifiers;
@end

@implementation MITMartyResourceDataSource
@dynamic resources;

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
        _mappingOperationQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}

- (NSArray*)resources
{
    __block NSArray *resources = nil;
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];

    [mainQueueContext performBlockAndWait:^{
        if ([self.resourceObjectIdentifiers count]) {
            NSMutableArray *mutableResources = [[NSMutableArray alloc] init];
            [self.resourceObjectIdentifiers enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
                NSManagedObject *object = [mainQueueContext objectWithID:objectID];
                [mutableResources addObject:object];
            }];

            resources = mutableResources;
        }
    }];

    return resources;
}

- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMartyResourceDataSource* dataSource, NSError *error))block
{
    NSURL *resourceReservations = [[NSURL alloc] initWithString:MITMartyDefaultServer];
    NSMutableString *urlPath = [NSMutableString stringWithFormat:@"/%@",MITMartyResourcePathPattern];

    if (queryString) {
        NSString *encodedString = [queryString urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
        [urlPath appendFormat:@"?%@&q=%@",@"format=json",encodedString];
    }

    NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
    request.HTTPShouldHandleCookies = NO;
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    RKMapping *mapping = [MITMartyResource objectMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:@"collection.items" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    requestOperation.managedObjectContext = self.managedObjectContext;

    RKFetchRequestManagedObjectCache *cache = [[RKFetchRequestManagedObjectCache alloc] init];
    requestOperation.managedObjectCache = cache;

    __weak MITMartyResourceDataSource *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        MITMartyResourceDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }

        NSManagedObjectContext *context = blockSelf.managedObjectContext;
        [context performBlock:^{
            blockSelf.lastFetched = [NSDate date];
            blockSelf.resourceObjectIdentifiers = [NSManagedObjectContext objectIDsForManagedObjects:[mappingResult array]];

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(blockSelf,nil);
                }
            }];
        }];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        MITMartyResourceDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else {
            DDLogError(@"failed to request Marty resources: %@",error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(blockSelf,error);
                }
            }];
        }
    }];

    [self.mappingOperationQueue addOperation:requestOperation];
}

@end
