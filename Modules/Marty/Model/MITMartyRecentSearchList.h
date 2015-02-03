#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMartyRecentSearchQuery;

@interface MITMartyRecentSearchList : MITManagedObject

@property (nonatomic, retain) NSOrderedSet *recentQueries;

@end

@interface MITMartyRecentSearchList (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMartyRecentSearchQuery *)value inRecentQueriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentQueriesAtIndex:(NSUInteger)idx;
- (void)insertRecentQueries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentQueriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentQueriesAtIndex:(NSUInteger)idx withObject:(MITMartyRecentSearchQuery *)value;
- (void)replaceRecentQueriesAtIndexes:(NSIndexSet *)indexes withRecentQueries:(NSArray *)values;
- (void)addRecentQueriesObject:(MITMartyRecentSearchQuery *)value;
- (void)removeRecentQueriesObject:(MITMartyRecentSearchQuery *)value;
- (void)addRecentQueries:(NSOrderedSet *)values;
- (void)removeRecentQueries:(NSOrderedSet *)values;
@end
