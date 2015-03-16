#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMobiusRecentSearchQuery;

@interface MITMobiusRecentSearchList : MITManagedObject

@property (nonatomic, retain) NSOrderedSet *recentQueries;

@end

@interface MITMobiusRecentSearchList (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusRecentSearchQuery *)value inRecentQueriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentQueriesAtIndex:(NSUInteger)idx;
- (void)insertRecentQueries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentQueriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentQueriesAtIndex:(NSUInteger)idx withObject:(MITMobiusRecentSearchQuery *)value;
- (void)replaceRecentQueriesAtIndexes:(NSIndexSet *)indexes withRecentQueries:(NSArray *)values;
- (void)addRecentQueriesObject:(MITMobiusRecentSearchQuery *)value;
- (void)removeRecentQueriesObject:(MITMobiusRecentSearchQuery *)value;
- (void)addRecentQueries:(NSOrderedSet *)values;
- (void)removeRecentQueries:(NSOrderedSet *)values;
@end
