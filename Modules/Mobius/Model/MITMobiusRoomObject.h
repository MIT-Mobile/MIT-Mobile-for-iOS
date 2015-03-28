#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResource;

@interface MITMobiusRoomObject : MITManagedObject <MKAnnotation>

@property (nonatomic, retain) NSString * roomName;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSOrderedSet *resources;
@end

@interface MITMobiusRoomObject (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusResource *)value inResourcesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromResourcesAtIndex:(NSUInteger)idx;
- (void)insertResources:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeResourcesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInResourcesAtIndex:(NSUInteger)idx withObject:(MITMobiusResource *)value;
- (void)replaceResourcesAtIndexes:(NSIndexSet *)indexes withResources:(NSArray *)values;
- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSOrderedSet *)values;
- (void)removeResources:(NSOrderedSet *)values;
@end
