#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMobile;
@class RKManagedObjectStore;

@interface MITCoreDataController : NSObject
@property (nonatomic,readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic,readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic,readonly) RKManagedObjectStore *managedObjectStore;

/** Returns a shared NSManagedObjectContext for use on the main queue. Objects managed
 *  by this context should not be modified; a background queue should be used instead.
 *
 *  @related performBackgroundUpdate:
 *  @related performBackgroundUpdateAndWait:
 */
@property (nonatomic,readonly) NSManagedObjectContext *mainQueueContext;

+ (instancetype)defaultController;

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel;

- (NSManagedObjectContext*)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType trackChanges:(BOOL)track;

/** Executes fetchRequest on a background context and
 *  returns the ordered set of IDs to the caller. Any changes
 *  made to registered objects will not be persisted.
 *
 */
- (void)performBackgroundFetch:(NSFetchRequest*)fetchRequest completion:(void (^)(NSOrderedSet *fetchedObjectIDs, NSError *error))block;

/** Creates a new NSManagedObjectContext for a background update and calls the
 *  passed block asynchronously. This method should only be called to kick off 
 *  a single, atomic CoreData operation. Calling this method recursively will result in strange and
 *  undefined behavior. The block is guaranteed to be called on the context's queue.
 *
 * Onces the block completes, any saved changes will be persisted and synched with
 *  the main queue context. If the block's context is not saved prior to returning
 *  its changes will be discarded.
 */
- (void)performBackgroundUpdate:(void (^)(NSManagedObjectContext *context, NSError **error))updateBlock completion:(void (^)(NSError *error))savedBlock;

/** Creates a new NSManagedObjectContext for a background update and calls the
 *  passed block synchronously. This method should only be called to kick off
 *  a single, atomic CoreData operation. This method is not re-entrant and should
 *  not be called recursively. The block is guaranteed to be
 *  called on the context's queue.
 *
 * Onces the block completes, any saved changes will be persisted and synched with
 *  the main queue context. If the block's context is not saved prior to returning
 *  its changes will be discarded.
 */
- (BOOL)performBackgroundUpdateAndWait:(BOOL (^)(NSManagedObjectContext *context, NSError **error))updateBlock error:(NSError**)error;

/** Flushes any un-persisted data in the background context to the persistent store.
 *  Once the save is completed, the passed block will be called on the main queue.
 *
 *  @param saved
 */
- (void)sync:(void (^)(NSError *error))saved;
@end
