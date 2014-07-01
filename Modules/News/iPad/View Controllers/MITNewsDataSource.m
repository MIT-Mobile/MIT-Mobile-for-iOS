#import "MITNewsDataSource.h"
#import "MITCoreDataController.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

@interface MITNewsDataSource ()
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic,copy) NSString *categoryIdentifier;
@property (nonatomic,strong) NSURL *nextPageURL;
@property (nonatomic,getter = isFeaturedStorySource) BOOL featuredStorySource;
@end

@implementation MITNewsDataSource
@synthesize managedObjectContext = _managedObjectContext;

+ (instancetype)allCategoriesDataSource
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];

    return dataSource;
}

+ (instancetype)featuredStoriesDataSource
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];
    dataSource.featuredStorySource = YES;

    return dataSource;
}

+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];

    [category.managedObjectContext performBlockAndWait:^{
        dataSource.categoryIdentifier = category.identifier;
    }];

    return dataSource;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
    }

    return self;
}


- (BOOL)hasNextPage
{
    return (BOOL)(self.nextPageURL != nil);
}

- (void)nextPage:(void(^)(NSError *error))block
{
    void (^wrappedBlock)(NSError *error) = ^(NSError *error) {
        if (block) {
            block(error);
        }
    };

    if (![self hasNextPage]) {
        wrappedBlock(nil);
        return;
    }

    

}

- (void)refresh:(void(^)(NSError *error))block
{

}

@end
