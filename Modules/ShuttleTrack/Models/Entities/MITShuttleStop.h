#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"
#import <MapKit/MapKit.h>

@class MITShuttlePrediction, MITShuttleRoute, MITShuttleVehicle;

@interface MITShuttleStop : MITManagedObject <MITMappedObject, MKAnnotation>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * predictionsURL;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * stopNumber;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSOrderedSet *predictions;
@property (nonatomic, retain) NSOrderedSet *routes;

// Computed
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (MITShuttlePrediction *)nextPredictionForRoute:(MITShuttleRoute *)route;
- (MITShuttlePrediction *)nextPredictionForVehicle:(MITShuttleVehicle *)vehicle;

@end

@interface MITShuttleStop (CoreDataGeneratedAccessors)

- (void)insertObject:(MITShuttlePrediction *)value inPredictionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPredictionsAtIndex:(NSUInteger)idx;
- (void)insertPredictions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePredictionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPredictionsAtIndex:(NSUInteger)idx withObject:(MITShuttlePrediction *)value;
- (void)replacePredictionsAtIndexes:(NSIndexSet *)indexes withPredictions:(NSArray *)values;
- (void)addPredictionsObject:(MITShuttlePrediction *)value;
- (void)removePredictionsObject:(MITShuttlePrediction *)value;
- (void)addPredictions:(NSOrderedSet *)values;
- (void)removePredictions:(NSOrderedSet *)values;
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
