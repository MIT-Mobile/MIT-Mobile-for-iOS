#import <Foundation/Foundation.h>

@interface MITMobiusAttributesDataSource : NSObject
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,copy) NSArray *attributes;
@property (nonatomic,strong) NSDate *lastUpdated;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext NS_DESIGNATED_INITIALIZER;

/** Initializes the data source with a managed object context whose parent is the default
 *  main queue context.
 */
- (instancetype)init;

- (void)attributes:(void(^)(MITMobiusAttributesDataSource *dataSource, NSError* error))completion;
@end
