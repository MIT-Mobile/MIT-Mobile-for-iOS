#import "CoreDataManager.h"

#import "MITBuildInfo.h"
#import "MITLogging.h"
#import "MITCoreDataController.h"

// not sure what to call this, just a placeholder for now, still hard coding file name below
#define SQLLITE_PREFIX @"CoreDataXML."
NSString * const MITCoreDataThreadLocalContextKey = @"MITCoreDataThreadLocalContext";
static NSString * const MITCoreDataContextObserverTokenKey = @"MITContextObserverToken";
static NSString * const MITCoreDataThreadObserverTokenKey = @"MITThreadObserverTokenKey";

@interface CoreDataManager ()
@property (nonatomic,strong) NSSet *modelNames;
@end

@implementation CoreDataManager
@dynamic modelNames;

#pragma mark -
#pragma mark Class methods

+(id)coreDataManager {
	static CoreDataManager *sharedInstance;
	if (!sharedInstance) {
		sharedInstance = [CoreDataManager new];
	}
	return sharedInstance;
}

#pragma mark -
#pragma mark *** Public accessors ***

+ (NSArray *)fetchDataForAttribute:(NSString *)attributeName {
	return [[CoreDataManager coreDataManager] fetchDataForAttribute:attributeName];
}

+ (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor {
	return [[CoreDataManager coreDataManager] fetchDataForAttribute:attributeName sortDescriptor:sortDescriptor];
}

+ (void)clearDataForAttribute:(NSString *)attributeName {
	[[CoreDataManager coreDataManager] clearDataForAttribute:attributeName];
}

+ (id)insertNewObjectForEntityForName:(NSString *)entityName {
	return [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:entityName];
}

+ (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [[CoreDataManager coreDataManager] insertNewObjectWithNoContextForEntity:entityName];
}

+ (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
    return [[CoreDataManager coreDataManager] objectsForEntity:entityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
}

+ (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate {
    return [[CoreDataManager coreDataManager] objectsForEntity:entityName matchingPredicate:predicate];
}

+ (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value {
	return [[CoreDataManager coreDataManager] getObjectForEntity:entityName attribute:attributeName value:value];
}

+ (void)deleteObjects:(NSArray *)objects {
    [[CoreDataManager coreDataManager] deleteObjects:objects];
}

+ (void)deleteObject:(NSManagedObject *)object {
	[[CoreDataManager coreDataManager] deleteObject:object];
}

+ (void)saveData {
	[[CoreDataManager coreDataManager] saveData];
}

+ (void)saveDataWithTemporaryMergePolicy:(id)temporaryMergePolicy {
    NSManagedObjectContext *context = [CoreDataManager managedObjectContext];
    id originalMergePolicy = [context mergePolicy];
    [context setMergePolicy:NSOverwriteMergePolicy];
	[self saveData];
	[context setMergePolicy:originalMergePolicy];
}

+ (NSManagedObjectModel *)managedObjectModel {
	return [[CoreDataManager coreDataManager] managedObjectModel];
}

+ (NSManagedObjectContext *)managedObjectContext {
	return [[CoreDataManager coreDataManager] managedObjectContext];
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [[CoreDataManager coreDataManager] persistentStoreCoordinator];
}

#pragma mark -
#pragma mark CoreData object methods

// list all xcdatamodeld's here
- (NSSet*)modelNames
{
    NSMutableSet *modelSet = [NSMutableSet set];
    [modelSet addObject:@"PeopleDataModel"];
    [modelSet addObject:@"News"];
    [modelSet addObject:@"Emergency"];
    [modelSet addObject:@"ShuttleTrack"];
    [modelSet addObject:@"Calendar"];
    [modelSet addObject:@"CampusMap"];
    [modelSet addObject:@"Tours"];
    [modelSet addObject:@"QRReaderResult"];
    [modelSet addObject:@"FacilitiesLocations"];
    [modelSet addObject:@"LibrariesLocationsHours"];
    [modelSet addObject:@"Dining"];
    return modelSet;
}

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
	[request setEntity:entity];

	NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];

	return result;
}

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor {
    NSArray *result = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    if (self.managedObjectContext) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
        [request setEntity:entity];

        NSError *error;
        result = [self.managedObjectContext executeFetchRequest:request error:&error];
    }

	return result;
}

- (void)clearDataForAttribute:(NSString *)attributeName {
	for (id object in [self fetchDataForAttribute:attributeName]) {
		[self deleteObject:(NSManagedObject *)object];
	}
	[self saveData];
}

- (void)deleteObjects:(NSArray *)objects {
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
}

- (void)deleteObject:(NSManagedObject *)object {
	[self.managedObjectContext deleteObject:object];
}

- (void)deleteObjectsForEntity:(NSString*)entityName {
    NSArray *objects = [self objectsForEntity:entityName
                            matchingPredicate:[NSPredicate predicateWithValue:YES]];
    [self deleteObjects:objects];
}

- (id)insertNewObjectForEntityForName:(NSString *)entityName {
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
}

- (id)insertNewObjectForEntityForName:(NSString *)entityName context:(NSManagedObjectContext *)aManagedObjectContext {
	NSEntityDescription *entityDescription = [[self.managedObjectModel entitiesByName] objectForKey:entityName];
	return [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:aManagedObjectContext];
}

- (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [self insertNewObjectForEntityForName:entityName context:nil];
}

- (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;

	NSError *error = nil;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];

    if (error) {
        DDLogError(@"fetch for entity '%@' failed: %@", entityName, [error localizedDescription]);
    }

    // Should only return 'nil' on error
    return objects;
}

- (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate {
    return [self objectsForEntity:entityName matchingPredicate:predicate sortDescriptors:nil];
}

- (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K like %@", attributeName, value];
    NSArray *objects = [self objectsForEntity:entityName matchingPredicate:predicate];
    return [objects lastObject];
}

- (void)saveData {
    // Since the main thread managed object context
    // may not be at the root of the tree with the new MITCoreDataManager
    // we'll need to walk up the tree and bubble the save up until
    // everything is flushed to the PSC. As long as everything either uses
    // CoreDataManager xor MITCoreDataManager, things should work fine.
    //
    // Structure note: The CoreDataManager was build assuming that every context
    //  was per-thread and directly descended from the PSC:
    //  PS -> PSC -> MOCs (confinement)
    //
    // The current structure has several more levels in the hierarchy:
    //  PS -> PSC -> MOC (private) -> Main Queue MOC -> MOCs (confinement)
    //                             -> Background MOCs

    NSManagedObjectContext* (^bubbleUpSaveBlock)(NSManagedObjectContext*) = ^(NSManagedObjectContext *context) {
        NSError *error = nil;
        BOOL saveSucceeded = [context save:&error];

        if (saveSucceeded) {
            return context.parentContext;
        }

        NSMutableString *message = [NSMutableString stringWithFormat:@"failed to save managed object context %@: %@",context,error];

        NSArray *detailedErrors = [error userInfo][NSDetailedErrorsKey];
        [detailedErrors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [message appendFormat:@"\n\terror %d: %@", idx, obj];
        }];

        DDLogError(@"%@",message);
        return (NSManagedObjectContext*)nil;
    };

    __block NSManagedObjectContext *context = self.managedObjectContext;
    while (context != nil) {
        switch (context.concurrencyType) {
            case NSPrivateQueueConcurrencyType:
            case NSMainQueueConcurrencyType: {
                [context performBlockAndWait:^{
                    context = bubbleUpSaveBlock(context);
                }];
            } break;

            // Due to the CoreDataManager's MOC structure this should *only* be triggered on the first pass through.
            default: {
                context = bubbleUpSaveBlock(context);
            }
        }
    }
}

#pragma mark -
#pragma mark Core Data stack

// modified to allow safe multithreaded Core Data use
- (NSManagedObjectContext *)managedObjectContext {
    if ([NSThread isMainThread]) {
        return [[MITCoreDataController defaultController] mainQueueContext];
    } else {
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSManagedObjectContext *localContext = threadDictionary[MITCoreDataThreadLocalContextKey];

        if (!localContext) {
            localContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSConfinementConcurrencyType trackChanges:NO];

            __weak NSManagedObjectContext *weakContext = localContext;
            id contextToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                                                object:[[MITCoreDataController defaultController] mainQueueContext]
                                                                                 queue:nil
                                                                            usingBlock:^(NSNotification *note) {
                                                                                [weakContext mergeChangesFromContextDidSaveNotification:note];
                                                                            }];

            id threadToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSThreadWillExitNotification
                                                                               object:[NSThread currentThread]
                                                                                queue:nil
                                                                           usingBlock:^(NSNotification *note) {
                                                                               NSThread *thread = (NSThread*)[note object];

                                                                               id threadToken = [thread threadDictionary][MITCoreDataThreadObserverTokenKey];
                                                                               [[NSNotificationCenter defaultCenter] removeObserver:threadToken];

                                                                               id contextToken = [thread threadDictionary][MITCoreDataContextObserverTokenKey];
                                                                               [[NSNotificationCenter defaultCenter] removeObserver:contextToken];
                                                                           }];

            threadDictionary[MITCoreDataContextObserverTokenKey] = contextToken;
            threadDictionary[MITCoreDataThreadObserverTokenKey] = threadToken;
            threadDictionary[MITCoreDataThreadLocalContextKey] = localContext;
        }

        return localContext;
    }
}

- (NSManagedObjectModel *)managedObjectModel {
    return [[MITCoreDataController defaultController].persistentStoreCoordinator managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    return [MITCoreDataController defaultController].persistentStoreCoordinator;

}


#pragma mark -
#pragma mark Application's documents directory
/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)storeFileName {
	NSString *currentFileName = [self currentStoreFileName];

	if (![[NSFileManager defaultManager] fileExistsAtPath:currentFileName]) {
		NSInteger maxVersion = 0;
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:NULL];
		// find all files like CoreDataXML.* and pick the latest one
		for (NSString *file in files) {
			if ([file hasPrefix:SQLLITE_PREFIX] && [file hasSuffix:@".sqlite"]) {
				// if version is something like 3:4M, this takes 3 to be the pre-existing version
				NSInteger version = [[[file componentsSeparatedByString:@"."] objectAtIndex:1] intValue];
				if (version >= maxVersion) {
					maxVersion = version;
					currentFileName = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:file];
				}
			}
		}
	}

	DDLogVerbose(@"Core Data stored at %@", currentFileName);
	return currentFileName;
}

- (NSString *)currentStoreFileName {
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"CoreDataXML.%@.sqlite", [MITBuildInfo revision]]];
}

#pragma mark -
#pragma mark Migration methods

- (BOOL)migrateData
{
	NSError *error = nil;

	NSString *sourcePath = [self storeFileName];
	NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
	NSURL *destURL = [NSURL fileURLWithPath: [self currentStoreFileName]];

	DDLogVerbose(@"Attempting to migrate from %@ to %@", [[self storeFileName] lastPathComponent], [[self currentStoreFileName] lastPathComponent]);

	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																							  URL:sourceURL
																							error:&error];

	if (sourceMetadata == nil) {
		DDLogError(@"Failed to fetch metadata with error %d: %@", [error code], [error userInfo]);
		return NO;
	}

	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil
																	forStoreMetadata:sourceMetadata];

	if (sourceModel == nil) {
		DDLogError(@"Failed to create source model");
		return NO;
	}

	NSManagedObjectModel *destinationModel = [self managedObjectModel];

	if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		DDLogError(@"No persistent store incompatilibilities detected, cancelling");
		return YES;
	}

	DDLogVerbose(@"source model entities: %@", [[sourceModel entityVersionHashesByName] description]);
	DDLogVerbose(@"destination model entities: %@", [[destinationModel entityVersionHashesByName] description]);

	NSMappingModel *mappingModel;

	// try to get a mapping automatically first
	mappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel
													 destinationModel:destinationModel
																error:&error];

	if (mappingModel == nil) {
		DDLogWarn(@"Could not create inferred mapping model: %@", [error userInfo]);
		// try again with xcmappingmodel files we created
		mappingModel = [NSMappingModel mappingModelFromBundles:nil
												forSourceModel:sourceModel
                                              destinationModel:destinationModel];

		if (mappingModel == nil) {
			DDLogError(@"Failed to create mapping model");
			return NO;
		}
	}


	NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey:NSSQLiteStoreType];
	Class sqliteStoreClass = (Class)[classValue pointerValue];
	Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];

	NSMigrationManager *manager = [[sqliteStoreMigrationManagerClass alloc]
								   initWithSourceModel:sourceModel destinationModel:destinationModel];

	if (![manager migrateStoreFromURL:sourceURL type:NSSQLiteStoreType options:nil withMappingModel:mappingModel
					 toDestinationURL:destURL destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
		DDLogError(@"Migration failed with error %d: %@", [error code], [error userInfo]);
		return NO;
	}

	if (![[NSFileManager defaultManager] removeItemAtPath:sourcePath error:&error]) {
		DDLogWarn(@"Failed to remove old store with error %d: %@", [error code], [error userInfo]);
	}
    
	DDLogVerbose(@"Migration complete!");
	return YES;
	
}

@end
