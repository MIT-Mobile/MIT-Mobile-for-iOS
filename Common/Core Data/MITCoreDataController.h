#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MITCoreDataController : NSObject
- (id)initWithPersistentStoreCoodinator:(NSPersistentStoreCoordinator*)coordinator;

/** Returns a shared NSManagedObjectContext for use on the main queue. Objects managed
 *  by this context should not be modified; a background queue should be used instead.
 *
 *  @related performBackgroundUpdate:
 *  @related performBackgroundUpdateAndWait:
 */
- (NSManagedObjectContext*)mainQueueContext;

/** Creates a new NSManagedObjectContext for background updates and calls the
 * passed block asynchronously. The block is guaranteed to be called on the
 * same queue as the NSManagedObjectContext.
 *
 * Onces the block completes, any saved changes will be persisted and synched with
 *  the main queue context. If the block's context is not saved prior to returning
 *  from the block, its changes will be discarded.
 */
- (void)performBackgroundUpdate:(void (^)(NSManagedObjectContext *context))block;

/** Creates a new NSManagedObjectContext for background updates and calls the
 * passed block synchronously. The block is guaranteed to be called on the
 * same queue as the NSManagedObjectContext.
 *
 * Onces the block completes, any saved changes will be persisted and synched with
 *  the main queue context. If the block's context is not saved prior to returning
 *  from the block, its changes will be discarded.
 */
- (void)performBackgroundUpdateAndWait:(void (^)(NSManagedObjectContext *context))block;

/** Flushes any un-persisted data to the persistent store.
 *  Once the save is completed, the passed block will be called.
 *  The block is guaranteed to be called on the main queue.
 *
 *  @param saved
 */
- (void)sync:(void (^)(NSError *error))saved;
@end
