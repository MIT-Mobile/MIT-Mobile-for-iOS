#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITNewsCategory;
@class MITNewsStory;

@interface MITNewsDataSource : NSObject
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) NSOrderedSet *objects;
@property (nonatomic) NSUInteger maximumNumberOfItemsPerPage;

// For subclass use only
//  Called when the first instance of a subclass
//  is initialized.
+ (BOOL)clearCachedObjectsWithManagedObjectContext:(NSManagedObjectContext*)context error:(NSError**)error;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (BOOL)hasNextPage;
- (BOOL)nextPage:(void(^)(NSError *error))block;
- (void)refresh:(void(^)(NSError *error))block;
@end
