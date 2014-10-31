#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITToursLink, MITToursStop;

@interface MITToursTour : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * shortTourDescription;
@property (nonatomic, retain) NSNumber * lengthInKM;
@property (nonatomic, retain) NSString * descriptionHTML;
@property (nonatomic, retain) NSNumber * estimatedDurationInMinutes;
@property (nonatomic, retain) NSOrderedSet *links;
@property (nonatomic, retain) NSOrderedSet *stops;

@property (nonatomic, readonly) NSArray *mainLoopStops;
@property (nonatomic, readonly) NSArray *sideTripsStops;

- (NSString *)durationString;
- (NSString *)localizedLengthString;

@end

@interface MITToursTour (CoreDataGeneratedAccessors)

- (void)insertObject:(MITToursLink *)value inLinksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLinksAtIndex:(NSUInteger)idx;
- (void)insertLinks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLinksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLinksAtIndex:(NSUInteger)idx withObject:(MITToursLink *)value;
- (void)replaceLinksAtIndexes:(NSIndexSet *)indexes withLinks:(NSArray *)values;
- (void)addLinksObject:(MITToursLink *)value;
- (void)removeLinksObject:(MITToursLink *)value;
- (void)addLinks:(NSOrderedSet *)values;
- (void)removeLinks:(NSOrderedSet *)values;
- (void)insertObject:(MITToursStop *)value inStopsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStopsAtIndex:(NSUInteger)idx;
- (void)insertStops:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStopsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStopsAtIndex:(NSUInteger)idx withObject:(MITToursStop *)value;
- (void)replaceStopsAtIndexes:(NSIndexSet *)indexes withStops:(NSArray *)values;
- (void)addStopsObject:(MITToursStop *)value;
- (void)removeStopsObject:(MITToursStop *)value;
- (void)addStops:(NSOrderedSet *)values;
- (void)removeStops:(NSOrderedSet *)values;
@end
