#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMartyResource;

@interface MITMartyMapObject : MITManagedObject <MKAnnotation>

@property (nonatomic, retain) NSString *roomName;
@property (nonatomic, retain) NSOrderedSet *resources;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@end

@interface MITMartyMapObject (CoreDataGeneratedAccessors)

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
