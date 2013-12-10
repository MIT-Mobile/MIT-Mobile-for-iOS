#import "MITCoreDataController.h"
#import "MITAdditions.h"
#import "MIT_MobileAppDelegate.h"

@interface MITCoreDataController ()
@property (strong) NSPersistentStoreCoordinator *storeCoordinator;
@property (strong) NSManagedObjectContext *rootContext;

@property (nonatomic,strong) NSManagedObjectContext *backgroundContext;
@property (strong) id backgroundContextNotificationToken;

@property (nonatomic,strong) NSManagedObjectContext *mainQueueContext;
@end


@implementation MITCoreDataController
+ (instancetype)defaultController
{
    return [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
}

- (instancetype)initWithPersistentStoreCoodinator:(NSPersistentStoreCoordinator*)coordinator
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

- (void)performBackgroundFetch:(NSFetchRequest*)fetchRequest completion:(void (^)(NSOrderedSet *fetchedObjectIDs, NSError *error))block
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.mainQueueContext;
    backgroundContext.retainsRegisteredObjects = YES;

    [backgroundContext performBlock:^{
        NSError *error = nil;
        NSArray *fetchResults = [backgroundContext executeFetchRequest:fetchRequest error:&error];

        NSArray *objectIDs = [NSManagedObjectContext objectIDsForManagedObjects:fetchResults];
        NSOrderedSet *fetchedIDs = [NSOrderedSet orderedSetWithArray:objectIDs];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (block) {
                block(fetchedIDs, error);
            }
        });
    }];
}

- (void)performBackgroundUpdate:(void (^)(NSManagedObjectContext *context, NSError **error))update completion:(void (^)(NSError *error))complete;
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.backgroundContext;

    [backgroundContext performBlock:^{
        __block NSError *error = nil;

        if (update) {
            update(backgroundContext, &error);
        }

        if (error) {
            DDLogError(@"Failed to complete update to context: %@",error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (complete) {
                    complete(error);
                }
            }];
        } else {
            [backgroundContext.parentContext performBlock:^{
                NSError *parentSaveError = nil;
                [backgroundContext.parentContext save:&parentSaveError];

                if (parentSaveError) {
                    DDLogError(@"Failed to save root background context: %@", parentSaveError);
                }

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (complete) {
                        complete(parentSaveError);
                    }
                }];
            }];
        }
    }];
}

- (void)performBackgroundUpdateAndWait:(void (^)(NSManagedObjectContext *context, NSError **error))update completion:(void (^)(NSError *error))complete;
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = self.backgroundContext;

    [backgroundContext performBlockAndWait:^{
        __block NSError *error = nil;

        if (update) {
            update(backgroundContext, &error);
        }

        if (error) {
            DDLogError(@"Failed to complete update to context: %@",error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (complete) {
                    complete(error);
                }
            }];
        } else {
            [backgroundContext.parentContext performBlock:^{
                NSError *parentSaveError = nil;
                [backgroundContext.parentContext save:&parentSaveError];

                if (parentSaveError) {
                    DDLogError(@"Failed to save root background context: %@", parentSaveError);
                }

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (complete) {
                        complete(parentSaveError);
                    }
                }];
            }];
        }
    }];
}

@end
