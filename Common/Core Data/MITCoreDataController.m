#import "MITCoreDataController.h"
#import "MITAdditions.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobile.h"
#import "MITMobileResource.h"
#import "MITBuildInfo.h"
#import "MITMapModelController.h"
#import "CoreDataManager.h"

static NSString * const MITPersistentStoreMetadataKey = @"MITCoreDataPersistentStoreState";
static NSString * const MITPersistentStoreMetadataURLKey = @"MITPersistentStoreMetadataURL";
static NSString * const MITPersistentStoreMetadataRevisionKey = @"MITPersistentStoreMetadataRevision";

@interface MITCoreDataController ()
@property (nonatomic,strong) RKManagedObjectStore *managedObjectStore;

@property (nonatomic,readonly) NSURL *persistentStoreURL;
@property (nonatomic,readonly) NSString *persistentStoreRevision;
- (void)setPersistentStoreURL:(NSURL*)url withRevision:(NSString*)revision;


- (BOOL)needsToRelocateLegacyStore;
- (BOOL)relocateLegacyStore:(NSError**)error;
@end

@implementation MITCoreDataController
@synthesize managedObjectModel = _managedObjectModel;

+ (instancetype)defaultController
{
    return [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    NSParameterAssert(managedObjectModel);

    self = [super init];
    if (self) {
        _managedObjectModel = managedObjectModel;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [self loadPersistentStore];

        _managedObjectStore = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:_persistentStoreCoordinator];
        [_managedObjectStore createManagedObjectContexts];
    }

    return self;
}

#pragma mark - Stack initialization
- (void)loadPersistentStore
{
    if ([self needsToRelocateLegacyStore]) {
        NSError *error = nil;
        [self relocateLegacyStore:&error];

        if (error) {
            DDLogError(@"failed to migrate legacy persistent store: %@",error);
        }
    }

    if (!self.persistentStoreURL) {
        NSURL *documentsURL = [self userDocumentsURL];
        NSUUID *uuid = [NSUUID UUID];

        NSURL *persistentStoreURL = [[NSURL URLWithString:[uuid UUIDString]
                                            relativeToURL:documentsURL] absoluteURL];
        [self setPersistentStoreURL:persistentStoreURL withRevision:[MITBuildInfo revision]];
    }

    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @(YES),
                              NSInferMappingModelAutomaticallyOption : @(YES)};
    NSPersistentStore *store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:self.persistentStoreURL
                                                                               options:options
                                                                                 error:&error];
    if (!store) {
        NSURL *persistentStoreURL = self.persistentStoreURL;
        DDLogError(@"failed to create persistent store at URL '%@': %@",persistentStoreURL,error);

        if ([persistentStoreURL checkResourceIsReachableAndReturnError:nil]) {
            DDLogError(@"store exists, but failed to load (revision %@). The store will be re-created",self.persistentStoreRevision);
            
            [[NSFileManager defaultManager] removeItemAtURL:persistentStoreURL error:nil];

            // Update the revision
            [self setPersistentStoreURL:persistentStoreURL withRevision:[MITBuildInfo revision]];

            store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                              configuration:nil
                                                                        URL:persistentStoreURL
                                                                    options:options
                                                                      error:&error];
        }
        
        if (!store) {
            DDLogError(@"Persistent store could not be created, falling back to a volatile store");
            store = [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                              configuration:nil
                                                                        URL:nil
                                                                    options:nil
                                                                      error:&error];
            NSAssert(store,@"failed to create a persistent store: %@",error);
        }
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.persistentStoreURL path]]) {
        NSError *error = nil;
        BOOL success = [self.persistentStoreURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
        if (!success) {
            DDLogWarn(@"Failed to exclude item at path '%@' from Backup: %@",[self.persistentStoreURL path],error);
        }
    }
}

#pragma mark Persistent Store Metadata
- (void)setPersistentStoreURL:(NSURL*)url withRevision:(NSString*)revision
{
    @synchronized([self class]) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if (!url) {
            [standardUserDefaults removeObjectForKey:MITPersistentStoreMetadataURLKey];
            [standardUserDefaults removeObjectForKey:MITPersistentStoreMetadataRevisionKey];
        } else {
            [standardUserDefaults setURL:url forKey:MITPersistentStoreMetadataURLKey];

            if (revision) {
                [standardUserDefaults setObject:revision forKey:MITPersistentStoreMetadataRevisionKey];
            } else {
                [standardUserDefaults setObject:[MITBuildInfo revision] forKey:MITPersistentStoreMetadataRevisionKey];
            }
        }
    }
}

- (NSURL*)persistentStoreURL
{
    return [[NSUserDefaults standardUserDefaults] URLForKey:MITPersistentStoreMetadataURLKey];
}

- (NSString*)persistentStoreRevision
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:MITPersistentStoreMetadataRevisionKey];
}

#pragma mark Migration Helpers
- (NSURL*)userDocumentsURL
{
    NSError *error = nil;
    NSURL *documentsURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                 inDomain:NSUserDomainMask
                                                        appropriateForURL:nil
                                                                   create:YES
                                                                    error:&error];
    NSAssert(error == nil,@"failed to get path to user's document directory: %@", error);
    return documentsURL;
}

- (BOOL)needsToRelocateLegacyStore
{
    NSString *currentStorePath = [[CoreDataManager coreDataManager] storeFileName];

    return [[NSFileManager defaultManager] fileExistsAtPath:currentStorePath];
}

- (BOOL)relocateLegacyStore:(NSError**)error
{
    NSError *localError = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [fileManager URLForDirectory:NSDocumentDirectory
                                              inDomain:NSUserDomainMask
                                     appropriateForURL:nil
                                                create:YES
                                                 error:&localError];
    if (localError) {
        if (error) {
            (*error) = localError;
        }

        DDLogError(@"failed to get path to user's document directory: %@", localError);
        return NO;
    }

    NSURL *legacyStoreURL = [NSURL fileURLWithPath:[[CoreDataManager coreDataManager] storeFileName]];
    NSUUID *storeUUID = [NSUUID UUID];
    NSURL *relocatedStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@.sqlite", [storeUUID UUIDString]]
                                      relativeToURL:documentsURL];

    [fileManager copyItemAtURL:legacyStoreURL toURL:relocatedStoreURL error:&localError];
    if (localError) {
        if (error) {
            (*error) = localError;
        }

        DDLogError(@"failed to copy legacy store at path '%@': %@",[legacyStoreURL path],localError);
        return NO;
    }

    NSArray *nameComponents = [[legacyStoreURL lastPathComponent] componentsSeparatedByString:@"."];
    [self setPersistentStoreURL:relocatedStoreURL withRevision:nameComponents[1]];

    [fileManager removeItemAtURL:legacyStoreURL error:&localError];
    if (localError) {
        if (error) {
            (*error) = localError;
        }

        DDLogWarn(@"failed to remove legacy store at path '%@': %@",[legacyStoreURL path],localError);
        return NO;
    }

    return YES;
}

#pragma mark - Dynamic Property
- (NSManagedObjectContext*)mainQueueContext
{
    return [self.managedObjectStore mainQueueManagedObjectContext];
}

#pragma mark - Public Methods
- (void)sync:(void (^)(NSError *))saved
{
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlock:^{
        NSError *error = nil;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];

        if (error) {
            DDLogError(@"Failed to save background context with error %@", error);

            if (saved) {
                saved(error);
            }
        } else {
            if (saved) {
                saved(nil);
            }
        }
    }];
}

- (NSManagedObjectContext*)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType trackChanges:(BOOL)track
{
    if (concurrencyType == NSConfinementConcurrencyType) {
        // Attempting to create a legacy context for use with the
        // older CoreDataManager-rooted stack. The track changes option is ignored
        // here (for now at least). Don't worry about storing this in a thread
        // somewhere, the CDM will take care of it
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        context.persistentStoreCoordinator = self.persistentStoreCoordinator;
        return context;
    } else {
        return [self.managedObjectStore newChildManagedObjectContextWithConcurrencyType:concurrencyType tracksChanges:track];
    }
}

- (void)performBackgroundFetch:(NSFetchRequest*)fetchRequest completion:(void (^)(NSOrderedSet *fetchedObjectIDs, NSError *error))block
{
    [self performBackgroundFetch:fetchRequest intoManagedObjectContext:nil completion:block];
}

- (void)performBackgroundFetch:(NSFetchRequest*)fetchRequest intoManagedObjectContext:(NSManagedObjectContext*)context completion:(void (^)(NSOrderedSet *fetchedObjectIDs, NSError *error))block
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
                if (context) {
                    NSArray *fetchedObjects = [context objectsWithIDs:[fetchedIDs array]];
                    block([NSOrderedSet orderedSetWithArray:fetchedObjects], error);
                } else {
                    block(fetchedIDs,error);
                }
            }
        });
    }];
}

- (void)performBackgroundUpdate:(void (^)(NSManagedObjectContext *context, NSError **error))update completion:(void (^)(NSError *error))complete;
{
    NSManagedObjectContext *backgroundContext = [self.managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];

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
    NSManagedObjectContext *backgroundContext = [self.managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];

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
