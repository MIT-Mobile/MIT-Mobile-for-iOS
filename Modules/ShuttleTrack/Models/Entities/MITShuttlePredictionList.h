#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITShuttlePrediction;

@interface MITShuttlePredictionList : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * routeTitle;
@property (nonatomic, retain) NSString * routeURL;
@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) NSString * stopTitle;
@property (nonatomic, retain) NSString * stopURL;
@property (nonatomic, retain) NSOrderedSet *predictions;
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
