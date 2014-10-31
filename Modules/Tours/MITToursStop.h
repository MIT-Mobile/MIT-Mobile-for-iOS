#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMappedObject.h"
#import "MITManagedObject.h"
#import "CoreLocation+MITAdditions.h"

@class MITToursDirectionsToStop, MITToursImage, MITToursTour;

@interface MITToursStop : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * bodyHTML;
@property (nonatomic, retain) id coordinates;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * stopType;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) MITToursDirectionsToStop *directionsToNextStop;
@property (nonatomic, retain) NSOrderedSet *images;
@property (nonatomic, retain) MITToursTour *tour;

@property (nonatomic, readonly) CLLocation *locationForStop;

- (NSString *)thumbnailURL;

@end

@interface MITToursStop (CoreDataGeneratedAccessors)

- (void)insertObject:(MITToursImage *)value inImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(MITToursImage *)value;
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)values;
- (void)addImagesObject:(MITToursImage *)value;
- (void)removeImagesObject:(MITToursImage *)value;
- (void)addImages:(NSOrderedSet *)values;
- (void)removeImages:(NSOrderedSet *)values;

@end
