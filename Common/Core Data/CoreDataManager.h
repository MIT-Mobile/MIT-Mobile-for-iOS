#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

FOUNDATION_EXTERN NSString * const MITCoreDataThreadLocalContextKey;

@interface CoreDataManager : NSObject
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSSet *modelNames;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

+ (CoreDataManager*)coreDataManager;

+ (NSArray *)fetchDataForAttribute:(NSString *)attributeName;
+ (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor;
+ (void)clearDataForAttribute:(NSString *)attributeName;

+ (id)insertNewObjectForEntityForName:(NSString *)entityName; //added by blpatt
+ (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName;
+ (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
+ (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate;
+ (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value; //added by blpatt

+ (void)deleteObjects:(NSArray *)objects;
+ (void)deleteObject:(NSManagedObject *)object;
+ (void)saveData;
+ (void)saveDataWithTemporaryMergePolicy:(id)temporaryMergePolicy;

+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSArray *)fetchDataForAttribute:(NSString *)attributeName;
- (NSArray *)fetchDataForAttribute:(NSString *)attributeName sortDescriptor:(NSSortDescriptor *)sortDescriptor;
- (void)clearDataForAttribute:(NSString *)attributeName;

- (id)insertNewObjectForEntityForName:(NSString *)entityName; //added by blpatt
- (id)insertNewObjectWithNoContextForEntity:(NSString *)entityName;
- (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
- (NSArray*)objectsForEntity:(NSString *)entityName matchingPredicate:(NSPredicate *)predicate;
- (id)getObjectForEntity:(NSString *)entityName attribute:(NSString *)attributeName value:(id)value; //added by blpatt

- (void)deleteObjects:(NSArray *)objects;
- (void)deleteObject:(NSManagedObject *)object;
- (void)deleteObjectsForEntity:(NSString*)entityName;
- (void)saveData;

// added for migrating store
-(NSString *)storeFileName;
-(NSString *)currentStoreFileName;
-(BOOL)migrateData;

@end
