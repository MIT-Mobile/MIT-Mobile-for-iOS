#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttleVehicle;

@interface MITShuttleVehicleList : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * agency;
@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * routeURL;
@property (nonatomic, retain) NSOrderedSet *vehicles;
@property (nonatomic) BOOL scheduled;
@property (nonatomic) BOOL predictable;
@end

@interface MITShuttleVehicleList (CoreDataGeneratedAccessors)

- (void)insertObject:(MITShuttleVehicle *)value inVehiclesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromVehiclesAtIndex:(NSUInteger)idx;
- (void)insertVehicles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeVehiclesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInVehiclesAtIndex:(NSUInteger)idx withObject:(MITShuttleVehicle *)value;
- (void)replaceVehiclesAtIndexes:(NSIndexSet *)indexes withVehicles:(NSArray *)values;
- (void)addVehiclesObject:(MITShuttleVehicle *)value;
- (void)removeVehiclesObject:(MITShuttleVehicle *)value;
- (void)addVehicles:(NSOrderedSet *)values;
- (void)removeVehicles:(NSOrderedSet *)values;
@end
