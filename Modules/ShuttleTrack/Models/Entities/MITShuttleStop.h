#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"
#import <MapKit/MapKit.h>

@class MITShuttlePredictionList, MITShuttlePrediction, MITShuttleRoute, MITShuttleVehicle;

@interface MITShuttleStop : MITManagedObject <MITMappedObject, MKAnnotation>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * predictionsURL;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * stopNumber;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) MITShuttlePredictionList *predictionList;
@property (nonatomic, retain) MITShuttleRoute *route;
@property (nonatomic, retain) NSString *routeId;

+ (RKMapping *)objectMappingFromDetail;
+ (RKMapping *)objectMappingFromRoutes;
+ (RKMapping *)objectMappingFromRouteDetail;
+ (RKMapping *)objectMappingFromPredictionList;

// Computed
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly) NSString *stopAndRouteIdTuple;

- (MITShuttlePrediction *)nextPrediction;
- (MITShuttlePrediction *)nextPredictionForVehicle:(MITShuttleVehicle *)vehicle;

@end

@interface MITShuttleStop (CoreDataGeneratedAccessors)

- (void)insertObject:(MITShuttleRoute *)value inRoutesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRoutesAtIndex:(NSUInteger)idx;
- (void)insertRoutes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRoutesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRoutesAtIndex:(NSUInteger)idx withObject:(MITShuttleRoute *)value;
- (void)replaceRoutesAtIndexes:(NSIndexSet *)indexes withRoutes:(NSArray *)values;
- (void)addRoutesObject:(MITShuttleRoute *)value;
- (void)removeRoutesObject:(MITShuttleRoute *)value;
- (void)addRoutes:(NSOrderedSet *)values;
- (void)removeRoutes:(NSOrderedSet *)values;
@end
