#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMartyResource;

@interface MartyMapObject : NSManagedObject

@property (nonatomic, retain) NSString * buildingName;
@property (nonatomic, retain) NSOrderedSet *resources;
@end

@interface MartyMapObject (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMartyResource *)value inResourcesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromResourcesAtIndex:(NSUInteger)idx;
- (void)insertResources:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeResourcesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInResourcesAtIndex:(NSUInteger)idx withObject:(MITMartyResource *)value;
- (void)replaceResourcesAtIndexes:(NSIndexSet *)indexes withResources:(NSArray *)values;
- (void)addResourcesObject:(MITMartyResource *)value;
- (void)removeResourcesObject:(MITMartyResource *)value;
- (void)addResources:(NSOrderedSet *)values;
- (void)removeResources:(NSOrderedSet *)values;
@end
