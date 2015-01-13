#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITShuttleDataSource;

//typedef void(^MITShuttleDataSourceCompletionBlock)(MITShuttleDataSource *dataSource, NSError *error);
extern NSString* const MITMobileErrorOwnerDeallocatedErrorFormat;
extern NSUInteger const MITMobileOwnerDeallocatedError;
extern NSError* MITDispatcherDeallocatedError(void *block);

@interface MITShuttleDataSource : NSObject <NSCopying>

@property(nonatomic) NSTimeInterval expiryInterval;

#pragma mark - For subclasses
@property(nonatomic,readonly) BOOL didFetchResults;
@property(nonatomic,strong) NSDate *fetchDate;
@property(nonatomic,strong) NSError *lastRequestError;

@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic,strong) NSOperationQueue *completionQueue;
@property(nonatomic,getter=isRequestActive) BOOL requestActive;

- (BOOL)needsUpdateFromServer;
- (void)_enqueueRequestCompletionBlock:(void (^)(void))block;
- (void)_performAsynchronousFetch:(void(^)(NSFetchedResultsController *fetchedResultsController, NSError *error))fetchCompletion;

@end
