#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITToursDirectionsToStop, MITToursImage, MITToursTour;

@interface MITToursStop : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) id coordinates;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * bodyHTML;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * stopType;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) MITToursDirectionsToStop *directionsToNextStop;
@property (nonatomic, retain) MITToursTour *tour;
@end

@interface MITToursStop (CoreDataGeneratedAccessors)

- (void)addImagesObject:(MITToursImage *)value;
- (void)removeImagesObject:(MITToursImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
