#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMapPlace, MITMapCategory;

@interface MITMapPlaceContent : MITManagedObject

@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) id categoryIds;
@property (nonatomic, strong) MITMapPlace *building;
@property (nonatomic, copy) NSOrderedSet *categories;

@end

@interface MITMapPlaceContent (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMapCategory *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(MITMapCategory *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(MITMapCategory *)value;
- (void)removeCategoriesObject:(MITMapCategory *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;

@end
