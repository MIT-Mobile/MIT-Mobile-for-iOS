#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttleStop, MITShuttleVehicle;

typedef NS_ENUM(NSUInteger, MITShuttleRouteStatus) {
    MITShuttleRouteStatusNotInService = 0,
    MITShuttleRouteStatusInService,
    MITShuttleRouteStatusUnknown
};

@interface MITShuttleRoute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * agency;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) id pathBoundingBox;
@property (nonatomic, retain) id pathSegments;
@property (nonatomic, retain) NSNumber * predictable;
@property (nonatomic, retain) NSString * predictionsURL;
@property (nonatomic, retain) NSString * routeDescription;
@property (nonatomic, retain) NSNumber * scheduled;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * vehiclesURL;
@property (nonatomic, retain) NSOrderedSet *stops;
@property (nonatomic, retain) NSOrderedSet *vehicles;

+ (RKMapping *)objectMappingFromAllRoutes;
+ (RKMapping *)objectMappingFromDetail;

- (NSArray *)nearestStopsWithCount:(NSInteger)count;
- (MITShuttleRouteStatus)status;
- (BOOL)isNextStop:(MITShuttleStop *)stop;
- (NSArray *)nextStops;

@end

@interface MITShuttleRoute (CoreDataGeneratedAccessors)

- (void)insertObject:(MITShuttleStop *)value inStopsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStopsAtIndex:(NSUInteger)idx;
- (void)insertStops:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStopsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStopsAtIndex:(NSUInteger)idx withObject:(MITShuttleStop *)value;
- (void)replaceStopsAtIndexes:(NSIndexSet *)indexes withStops:(NSArray *)values;
- (void)addStopsObject:(MITShuttleStop *)value;
- (void)removeStopsObject:(MITShuttleStop *)value;
- (void)addStops:(NSOrderedSet *)values;
- (void)removeStops:(NSOrderedSet *)values;
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
