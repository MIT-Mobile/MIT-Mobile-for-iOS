#import "MITCoreDataController.h"
#import "MITAdditions.h"

@interface MITCoreDataController ()
@property (strong) NSPersistentStoreCoordinator *storeCoordinator;
@property (strong) NSManagedObjectContext *rootContext;

@property (nonatomic,strong) NSManagedObjectContext *backgroundContext;
@property (strong) id backgroundContextNotificationToken;

@property (nonatomic,strong) NSManagedObjectContext *mainQueueContext;
@end


@implementation MITCoreDataController
- (id)initWithPersistentStoreCoodinator:(NSPersistentStoreCoordinator*)coordinator
{
    self = [super init];

    if (self) {
        if (coordinator) {
            _storeCoordinator = coordinator;


            NSManagedObjectContext *rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            rootContext.persistentStoreCoordinator = _storeCoordinator;
            _rootContext = rootContext;

            NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            backgroundContext.persistentStoreCoordinator = _storeCoordinator;

            __weak MITCoreDataController *coreDataController = self;
            id token = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                                         object:backgroundContext
                                                                          queue:nil
                                                                     usingBlock:^(NSNotification *note) {
                                                                         [coreDataController.mainQueueContext performBlockAndWait:^{
                                                                             [coreDataController.mainQueueContext mergeChangesFromContextDidSaveNotification:note];
                                                                         }];
                                                                     }];
            _backgroundContextNotificationToken = token;
            _backgroundContext = backgroundContext;

            NSManagedObjectContext *mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            //mainContext.parentContext = rootContext;
            mainContext.persistentStoreCoordinator = _storeCoordinator;
            mainContext.retainsRegisteredObjects = NO;
            _mainQueueContext = mainContext;
        } else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"Persistant store coordinator may not be nil"
                                         userInfo:nil];
        }
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.backgroundContextNotificationToken];
}

#pragma mark - Public Methods
- (void)sync:(void (^)(NSError *))saved
{
    [self.backgroundContext performBlock:^{
        NSError *error = nil;
        [self.backgroundContext save:&error];

        if (error) {
            DDLogError(@"Failed to save main queue context with error %@", error);

            if (saved) {
                saved(error);
            }
        }
    }];
}


- (void)performBackgroundUpdate:(void (^)(NSManagedObjectContext *context))block
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.backgroundContext;

    [backgroundContext performBlock:^{
        if (block) {
            block(backgroundContext);
        }

        [self.backgroundContext performBlockAndWait:^{
            NSError *error = nil;
            [self.backgroundContext save:&error];

            if (error) {
                DDLogError(@"Failed to save background context: %@", error);
            }
        }];
    }];
}

- (void)performBackgroundUpdateAndWait:(void (^)(NSManagedObjectContext *context))block
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.backgroundContext;

    [backgroundContext performBlockAndWait:^{
        if (block) {
            block(backgroundContext);
        }

        [self.backgroundContext performBlock:^{
            NSError *error = nil;
            [self.backgroundContext save:&error];

            if (error) {
                DDLogError(@"Failed to save background context: %@", error);
            }
        }];
    }];
}

@end
