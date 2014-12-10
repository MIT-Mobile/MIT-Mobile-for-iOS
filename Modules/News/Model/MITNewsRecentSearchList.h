#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITNewsRecentSearchQuery;

@interface MITNewsRecentSearchList : MITManagedObject

@property (nonatomic, retain) NSOrderedSet *recentQueries;
@end

@interface MITNewsRecentSearchList (CoreDataGeneratedAccessors)

- (void)insertObject:(MITNewsRecentSearchQuery *)value inRecentQueriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentQueriesAtIndex:(NSUInteger)idx;
- (void)insertRecentQueries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentQueriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentQueriesAtIndex:(NSUInteger)idx withObject:(MITNewsRecentSearchQuery *)value;
- (void)replaceRecentQueriesAtIndexes:(NSIndexSet *)indexes withRecentQueries:(NSArray *)values;
- (void)addRecentQueriesObject:(MITNewsRecentSearchQuery *)value;
- (void)removeRecentQueriesObject:(MITNewsRecentSearchQuery *)value;
- (void)addRecentQueries:(NSOrderedSet *)values;
- (void)removeRecentQueries:(NSOrderedSet *)values;
@end
