#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMapPlace, MITMapCategory, MITMapSearch, MITMapPlaceContent;

@interface MITMapCategory : MITManagedObject
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSSet *places;
@property (nonatomic, copy) NSSet *placeContents;
@property (nonatomic, copy) NSOrderedSet *children;
@property (nonatomic, strong) MITMapCategory *parent;
@property (nonatomic, strong) MITMapSearch *search;

- (NSString *)canonicalName;
- (NSString *)iconName;
- (NSString *)sectionIndexTitle;
- (NSArray *)allPlaces;

@end

@interface MITMapCategory (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(MITMapPlace *)value;
- (void)removePlacesObject:(MITMapPlace *)value;
- (void)addPlaces:(NSSet *)values;
- (void)removePlaces:(NSSet *)values;

- (void)addPlaceContentsObject:(MITMapPlaceContent *)value;
- (void)removePlaceContentsObject:(MITMapPlaceContent *)value;
- (void)addPlaceContents:(NSSet *)values;
- (void)removePlaceContents:(NSSet *)values;

- (void)insertObject:(MITMapCategory *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(MITMapCategory *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(MITMapCategory *)value;
- (void)removeChildrenObject:(MITMapCategory *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
@end
