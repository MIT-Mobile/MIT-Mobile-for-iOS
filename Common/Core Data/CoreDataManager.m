#import "CoreDataManager.h"
#import "MITBuildInfo.h"
#import <objc/runtime.h>

// not sure what to call this, just a placeholder for now, still hard coding file name below
#define SQLLITE_PREFIX @"CoreDataXML."


@implementation CoreDataManager

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;

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

+(NSArray *)fetchDataForAttribute:(NSString *)attributeName {
	return [[CoreDataManager coreDataManager] fetchDataForAttribute:attributeName];
}

+(NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor {
	return [[CoreDataManager coreDataManager] fetchDataForAttribute:attributeName sortDescriptor:sortDescriptor];
}

+(void)clearDataForAttribute:(NSString *)attributeName {
	[[CoreDataManager coreDataManager] clearDataForAttribute:attributeName];
}

+(id)insertNewObjectForEntityForName:(NSString *)entityName {
	return [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:entityName];
}

+(id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [[CoreDataManager coreDataManager] insertNewObjectWithNoContextForEntity:entityName];
}

// note this function will not handle objects that have circular references correctly
+(id)insertObjectGraph:(NSManagedObject *)managedObject {
	return [[CoreDataManager coreDataManager] insertObjectGraph:managedObject];
}

+(id)insertObjectGraph:(NSManagedObject *)managedObject context:(NSManagedObjectContext *)context {
	return [[CoreDataManager coreDataManager] insertObjectGraph:managedObject context:context];
}

+(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
    return [[CoreDataManager coreDataManager] objectsForEntity:entityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
}

+(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate {
    return [[CoreDataManager coreDataManager] objectsForEntity:entityName matchingPredicate:predicate];
}

+(id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value {
	return [[CoreDataManager coreDataManager] getObjectForEntity:entityName attribute:attributeName value:value];
}

+(void)deleteObjects:(NSArray *)objects {
    [[CoreDataManager coreDataManager] deleteObjects:objects];
}

+(void)deleteObject:(NSManagedObject *)object {
	[[CoreDataManager coreDataManager] deleteObject:object];
}

+(void)saveData {
	[[CoreDataManager coreDataManager] saveData];
}


+(NSManagedObjectModel *)managedObjectModel {
	return [[CoreDataManager coreDataManager] managedObjectModel];
}

+(NSManagedObjectContext *)managedObjectContext {
	return [[CoreDataManager coreDataManager] managedObjectContext];
}

+(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [[CoreDataManager coreDataManager] persistentStoreCoordinator];
}

#pragma mark -
#pragma mark CoreData object methods

-(NSArray *)fetchDataForAttribute:(NSString *)attributeName {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
	[request setEntity:entity];
	
	NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    // TODO: handle errors when Core Data calls fail
    [request release];
    
	return result;
}

-(NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];	// make a request object
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:attributeName inManagedObjectContext:self.managedObjectContext];	// tell the request what to look for
	[request setEntity:entity];
	
	NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    [request release];
    
	return result;
}

-(void)clearDataForAttribute:(NSString *)attributeName {
	for (id object in [self fetchDataForAttribute:attributeName]) {
		[self deleteObject:(NSManagedObject *)object];
	}
	[self saveData];
}

-(void)deleteObjects:(NSArray *)objects {
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
}

-(void)deleteObject:(NSManagedObject *)object {
	[self.managedObjectContext deleteObject:object];
}

-(id)insertNewObjectForEntityForName:(NSString *)entityName {
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
}

-(id)insertNewObjectForEntityForName:(NSString *)entityName context:(NSManagedObjectContext *)aManagedObjectContext {
    self.managedObjectContext;
	NSEntityDescription *entityDescription = [[managedObjectModel entitiesByName] objectForKey:entityName];
	return [[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:aManagedObjectContext] autorelease];
}

-(id)insertNewObjectWithNoContextForEntity:(NSString *)entityName {
	return [self insertNewObjectForEntityForName:entityName context:nil];
}

/*
 This method is not yet fully general it would not handle circular references or attributes that
 are other managedObjects.
 */
-(id)insertObjectGraph:(NSManagedObject *)managedObject context:(NSManagedObjectContext *)context {
	Class objectClass = [managedObject class];
	NSManagedObject *newManagedObject = [self insertNewObjectForEntityForName:NSStringFromClass(objectClass) context:context];	
	
	unsigned int outCount, i;
	
	objc_property_t *properties = class_copyPropertyList(objectClass, &outCount);
	
	for (i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];

		id propertyValue = [managedObject performSelector:NSSelectorFromString(propertyName)];
		
		NSString *propertyNameWithCapital = [propertyName 
			stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
			withString:[[propertyName substringToIndex:1] uppercaseString]];
		
		if(strcmp(property_getAttributes(property), "T@\"NSSet\",&,D,N") == 0) {
			for(NSManagedObject *element in [((NSSet *)propertyValue) allObjects]) {
				[newManagedObject 
				 performSelector:NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", propertyNameWithCapital])
				 withObject:[self insertObjectGraph:element context:context]];
			}
		} else {				
			if(![propertyValue isKindOfClass:[NSManagedObject class]]) {
				[newManagedObject 
					performSelector:NSSelectorFromString(
						[NSString stringWithFormat:@"set%@:", propertyNameWithCapital])
					withObject:[[propertyValue copy] autorelease]];
			}
		}
	}

	free(properties);
	return newManagedObject;
}

-(id) insertObjectGraph:(NSManagedObject *)managedObject {
	return [self insertObjectGraph:managedObject context:self.managedObjectContext];
}

-(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	[request setPredicate:predicate];
    if (sortDescriptors) {
        [request setSortDescriptors:sortDescriptors];
    }
	
	NSError *error;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];

    return ([objects count] > 0) ? objects : nil;
}

-(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate {
    return [self objectsForEntity:entityName matchingPredicate:predicate sortDescriptors:nil];
}

-(id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value {	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:[attributeName stringByAppendingString:@" like %@"], value];
    NSArray *objects = [self objectsForEntity:entityName matchingPredicate:predicate];
    return ([objects count] > 0) ? [objects lastObject] : nil;
}

-(void)saveData {
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
//        NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
//        NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
//        if(detailedErrors != nil && [detailedErrors count] > 0) {
//            for(NSError* detailedError in detailedErrors) {
//                NSLog(@"  DetailedError: %@", [detailedError userInfo]);
//            }
//        }
//        else {
//            NSLog(@"  %@", [error userInfo]);
//        }
	}	
}

#pragma mark -
#pragma mark Core Data stack

// modified to allow safe multithreaded Core Data use
-(NSManagedObjectContext *)managedObjectContext {
    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    NSManagedObjectContext *localContext = [threadDict objectForKey:@"MITCoreDataManagedObjectContext"];
    if (localContext) {
        return localContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        localContext = [[NSManagedObjectContext alloc] init];
        [localContext setPersistentStoreCoordinator: coordinator];
        [threadDict setObject:localContext forKey:@"MITCoreDataManagedObjectContext"];
        [localContext release];
    }
    return localContext;
}

# pragma mark Everything below here is auto-generated

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
	// override the autogenerated method -- see http://iphonedevelopment.blogspot.com/2009/09/core-data-migration-problems.html
	NSMutableArray *models = [[NSMutableArray alloc] initWithCapacity:2];
	// list all xcdatamodeld's here
	NSArray *allModels = [NSArray arrayWithObjects:@"Stellar", @"PeopleDataModel", @"News", @"Emergency", nil];
	for (NSString *modelName in allModels) {
		NSString *path = [[NSBundle mainBundle] pathForResource:modelName ofType:@"momd"];
        NSManagedObjectModel *aModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
		[models addObject:aModel];
        [aModel release];
	}
	
	managedObjectModel = [NSManagedObjectModel modelByMergingModels:models];
	[models release];
    
    return managedObjectModel;
	
	
	// any data model in this project will have the compiled MOM file attached to the main application bundle...
    //managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];	// so, specify nil to get any MOM files found in the main bundle
    //return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSURL *storeURL = [NSURL fileURLWithPath:[self storeFileName]];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])  {
		NSLog(@"CoreDataManager failed to create or access the persistent store: %@", [error userInfo]);
		
		// see if we failed because of changes to the db
		if (![[self storeFileName] isEqualToString:[self currentStoreFileName]]) {
			NSLog(@"This app has been upgraded since last use of Core Data. If it crashes on launch, reinstalling should fix it.");
			if ([self migrateData]) {
				NSLog(@"Attempting to recreate the persistent store...");
				storeURL = [NSURL fileURLWithPath:[self storeFileName]];
				if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
															  configuration:nil URL:storeURL options:options error:&error]) {
					NSLog(@"Failed to recreate the persistent store: %@", [error userInfo]);
				}
			} else {
				NSLog(@"Could not migrate data");
			}
		}
    }
	
    return persistentStoreCoordinator;
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
			if ([file hasPrefix:@"CoreDataXML."]) {
				// if version is something like 3:4M, this takes 3 to be the pre-existing version
				NSInteger version = [[[file componentsSeparatedByString:@"."] objectAtIndex:1] intValue];
				if (version >= maxVersion) {
					maxVersion = version;
					currentFileName = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:file];
				}
			}
		}
	}
	//NSLog(@"Core Data stored at %@", currentFileName);
	return currentFileName;
}

- (NSString *)currentStoreFileName {
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"CoreDataXML.%@.sqlite", MITBuildNumber]];
}

#pragma mark -
#pragma mark Migration methods

- (BOOL)migrateData
{	
	NSError *error;
	
	NSString *sourcePath = [self storeFileName];
	NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
	NSURL *destURL = [NSURL fileURLWithPath: [self currentStoreFileName]];
	
	NSLog(@"Attempting to migrate from %@ to %@", [[self storeFileName] lastPathComponent], [[self currentStoreFileName] lastPathComponent]);
		  
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																							  URL:sourceURL
																							error:&error];
	
	if (sourceMetadata == nil) {
		NSLog(@"Failed to fetch metadata with error %d: %@", [error code], [error userInfo]);
		return NO;
	}
	
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil 
																	forStoreMetadata:sourceMetadata];
	
	if (sourceModel == nil) {
		NSLog(@"Failed to create source model");
		return NO;
	}
	
	NSManagedObjectModel *destinationModel = [self managedObjectModel];

	if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		NSLog(@"No persistent store incompatilibilities detected, cancelling");
		return YES;
	}
	
	NSLog(@"source model entities: %@", [[sourceModel entityVersionHashesByName] description]);
	NSLog(@"destination model entities: %@", [[destinationModel entityVersionHashesByName] description]);
	
	NSMappingModel *mappingModel;
	
	// try to get a mapping automatically first
	mappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel 
													 destinationModel:destinationModel 
																error:&error];

	if (mappingModel == nil) {
		NSLog(@"Could not create inferred mapping model: %@", [error userInfo]);
		// try again with xcmappingmodel files we created
		mappingModel = [NSMappingModel mappingModelFromBundles:nil
												forSourceModel:sourceModel
										destinationModel:destinationModel];
		
		if (mappingModel == nil) {
			NSLog(@"Failed to create mapping model");
			return NO;
		}
	}
	
	
	NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey:NSSQLiteStoreType];
	Class sqliteStoreClass = (Class)[classValue pointerValue];
	Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
	
	NSMigrationManager *manager = [[[sqliteStoreMigrationManagerClass alloc]
								   initWithSourceModel:sourceModel destinationModel:destinationModel] autorelease];
	
	if (![manager migrateStoreFromURL:sourceURL type:NSSQLiteStoreType options:nil withMappingModel:mappingModel 
					 toDestinationURL:destURL destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
		NSLog(@"Migration failed with error %d: %@", [error code], [error userInfo]);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] removeItemAtPath:sourcePath error:&error]) {
		NSLog(@"Failed to remove old store with error %d: %@", [error code], [error userInfo]);
	}
	
	NSLog(@"Migration complete!");
	return YES;
	
}








#pragma mark -

-(void)dealloc {
	[managedObjectModel release];
	[managedObjectContext release];
	[persistentStoreCoordinator release];

	[super dealloc];
}

@end
