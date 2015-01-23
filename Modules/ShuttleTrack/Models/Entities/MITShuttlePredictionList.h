#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttlePrediction, MITShuttleStop, MITShuttleRoute;

@interface MITShuttlePredictionList : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) NSOrderedSet *predictions;
@property (nonatomic, retain) NSDate *updatedTime;
@property (nonatomic, retain) MITShuttleStop *stop;
@property (nonatomic, retain) MITShuttleRoute *route;

+ (RKMapping *)objectMappingFromDetail;
+ (RKMapping *)objectMappingFromStop;

@end

@interface MITShuttlePredictionList (CoreDataGeneratedAccessors)

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

@end
