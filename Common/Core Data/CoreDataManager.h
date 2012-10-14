#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject {
	NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSSet *modelNames;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

+(id)coreDataManager;

+(NSArray *)fetchDataForAttribute:(NSString *)attributeName;
+(NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor;
+(void)clearDataForAttribute:(NSString *)attributeName;

+(id)insertNewObjectForEntityForName:(NSString *)entityName; //added by blpatt
+(id)insertNewObjectWithNoContextForEntity:(NSString *)entityName;
+(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
+(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate;
+(id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value; //added by blpatt

+(void)deleteObjects:(NSArray *)objects;
+(void)deleteObject:(NSManagedObject *)object;
+(void)saveData;
+(void)saveDataWithTemporaryMergePolicy:(id)temporaryMergePolicy;
+(BOOL)wipeData;

+(NSManagedObjectModel *)managedObjectModel;
+(NSManagedObjectContext *)managedObjectContext;
+(NSPersistentStoreCoordinator *)persistentStoreCoordinator;

-(NSArray *)fetchDataForAttribute:(NSString *)attributeName;
-(NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor;
-(void)clearDataForAttribute:(NSString *)attributeName;

-(id)insertNewObjectForEntityForName:(NSString *)entityName; //added by blpatt
-(id)insertNewObjectWithNoContextForEntity:(NSString *)entityName;
-(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
-(id)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate;
-(id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value; //added by blpatt

-(void)deleteObjects:(NSArray *)objects;
-(void)deleteObject:(NSManagedObject *)object;
-(void)deleteObjectsForEntity:(NSString*)entityName;
-(void)saveData;
-(BOOL)wipeData;

// added for migrating store
-(NSString *)storeFileName;
-(NSString *)currentStoreFileName;
-(BOOL)migrateData;

@end
