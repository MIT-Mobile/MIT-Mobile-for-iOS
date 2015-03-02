#import <CoreData/CoreData.h>
#import "MITMobileResource.h"

/** The callback handler for any requests which can be fulfilled by
 *  CoreData.
 *
 *  @param objects A sorted set of the fetched objects. These are guaranteed to be in the main queue context. This will be nil if an error occurs.
 *  @param fetchRequest The fetch request used to retreive the returned objects.  This will be nil if an error occurs.
 *  @param lastUpdated The date of the last successfully refresh of the cached data.
 *  @param error An error.
 */
typedef void (^MITMobileManagedResult)(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error);

@interface MITMobileManagedResource : MITMobileResource
@property (nonatomic,readonly) NSManagedObjectModel *managedObjectModel;

- (instancetype)initWithName:(NSString *)name pathPattern:(NSString *)pathPattern managedObjectModel:(NSManagedObjectModel*)managedObjectModel;
- (NSFetchRequest*)fetchRequestForURL:(NSURL *)url;
- (NSArray*)fetchRequestForURLBlocks;

@end
