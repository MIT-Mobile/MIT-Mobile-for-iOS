#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class PeopleRecentSearchTerm;

@interface PeopleRecentSearchTermList : MITManagedObject

@property (nonatomic, retain) NSOrderedSet *recentSearchTermList;
@end

@interface PeopleRecentSearchTermList (CoreDataGeneratedAccessors)

- (void)insertObject:(PeopleRecentSearchTerm *)value inRecentSearchTermListAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentSearchTermListAtIndex:(NSUInteger)idx;
- (void)insertRecentSearchTermList:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentSearchTermListAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentSearchTermListAtIndex:(NSUInteger)idx withObject:(PeopleRecentSearchTerm *)value;
- (void)replaceRecentSearchTermListAtIndexes:(NSIndexSet *)indexes withRecentSearchTermList:(NSArray *)values;
- (void)addRecentSearchTermListObject:(PeopleRecentSearchTerm *)value;
- (void)removeRecentSearchTermListObject:(PeopleRecentSearchTerm *)value;
- (void)addRecentSearchTermList:(NSOrderedSet *)values;
- (void)removeRecentSearchTermList:(NSOrderedSet *)values;
@end
