//
//  MITShuttlePredictionList.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/16/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITShuttlePrediction;

@interface MITShuttlePredictionList : NSManagedObject

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
