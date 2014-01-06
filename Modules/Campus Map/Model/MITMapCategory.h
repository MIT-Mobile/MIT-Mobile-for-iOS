#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMapPlace, MITMapCategory;

@interface MITMapCategory : NSManagedObject
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSSet *places;
@property (nonatomic, copy) NSOrderedSet *children;
@property (nonatomic, strong) MITMapCategory *parent;

+ (NSString*)entityName;
- (NSString*)canonicalName;
@end

@interface MITMapCategory (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(MITMapPlace *)value;
- (void)removePlacesObject:(MITMapPlace *)value;
- (void)addPlaces:(NSSet *)values;
- (void)removePlaces:(NSSet *)values;

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
