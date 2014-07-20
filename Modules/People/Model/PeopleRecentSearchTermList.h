//
//  PeopleRecentSearchTermList.h
//  MIT Mobile
//
//  Created by Yev Motov on 7/18/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"


@interface PeopleRecentSearchTermList : MITManagedObject

@property (nonatomic, retain) NSOrderedSet *recentSearchTermList;
@end

@interface PeopleRecentSearchTermList (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inRecentSearchTermListAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecentSearchTermListAtIndex:(NSUInteger)idx;
- (void)insertRecentSearchTermList:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecentSearchTermListAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecentSearchTermListAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceRecentSearchTermListAtIndexes:(NSIndexSet *)indexes withRecentSearchTermList:(NSArray *)values;
- (void)addRecentSearchTermListObject:(NSManagedObject *)value;
- (void)removeRecentSearchTermListObject:(NSManagedObject *)value;
- (void)addRecentSearchTermList:(NSOrderedSet *)values;
- (void)removeRecentSearchTermList:(NSOrderedSet *)values;
@end
