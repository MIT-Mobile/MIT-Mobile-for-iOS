#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString* const MITNewsDataSourceDidBeginUpdatingNotification;
extern NSString* const MITNewsDataSourceDidEndUpdatingNotification;

@class MITNewsCategory;
@class MITNewsStory;

@interface MITNewsDataSource : NSObject
@property(nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,readonly,strong) NSOrderedSet *objects;
@property(nonatomic) NSUInteger maximumNumberOfItemsPerPage;
@property(nonatomic,readonly) BOOL isUpdating;
@property(nonatomic,strong) NSDate *refreshedAt;

// For subclass use only
//  Called when the first instance of a subclass
//  is initialized.
+ (BOOL)clearCachedObjectsWithManagedObjectContext:(NSManagedObjectContext*)context error:(NSError**)error;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (BOOL)hasNextPage;
- (void)nextPage:(void(^)(NSError *error))block;
- (void)refresh:(void(^)(NSError *error))block;
@end
