#import "MITNewsDataSource.h"

@protocol MITNewsCategoryDataSourceDelegate;

@interface MITNewsCategoryDataSource : MITNewsDataSource
@property(nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic,readonly,strong) NSDate *lastRefreshed;

// Convenience accessor for the @objects property. All objects
// are guaranteed to be of type MITNewsCategory.
@property(nonatomic,readonly) NSOrderedSet *categories;

- (instancetype)init;
@end