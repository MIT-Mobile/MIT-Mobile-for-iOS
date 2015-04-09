#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute, MITMobiusResourceAttributeValueSet, MITMobiusResourceDLC, MITMobiusResourceHours, MITMobiusResourceOwner, MITMobiusRoomSet, MITMobiusImage;

@interface MITMobiusResource : MITManagedObject <MITMappedObject,MKAnnotation>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * reservable;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSOrderedSet *attributeValues;
@property (nonatomic, retain) MITMobiusResourceDLC *dlc;
@property (nonatomic, retain) NSOrderedSet *images;
@property (nonatomic, retain) NSSet *hours;
@property (nonatomic, retain) NSOrderedSet *owners;
@property (nonatomic, retain) MITMobiusRoomSet *roomset;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (NSString *)getHoursStringForDate:(NSDate *)date;
- (BOOL)isOpenOnDate:(NSDate *)date;

@end

@interface MITMobiusResource (CoreDataGeneratedAccessors)
- (void)insertObject:(MITMobiusResourceAttributeValueSet *)value inAttributeValuesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttributeValuesAtIndex:(NSUInteger)idx;
- (void)insertAttributeValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttributeValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttributeValuesAtIndex:(NSUInteger)idx withObject:(MITMobiusResourceAttributeValueSet *)value;
- (void)replaceAttributeValuesAtIndexes:(NSIndexSet *)indexes withAttributeValues:(NSArray *)values;
- (void)addAttributeValuesObject:(MITMobiusResourceAttributeValueSet *)value;
- (void)removeAttributeValuesObject:(MITMobiusResourceAttributeValueSet *)value;
- (void)addAttributeValues:(NSOrderedSet *)values;
- (void)removeAttributeValues:(NSOrderedSet *)values;
- (void)addHoursObject:(MITMobiusResourceHours *)value;
- (void)removeHoursObject:(MITMobiusResourceHours *)value;
- (void)addHours:(NSSet *)values;
- (void)removeHours:(NSSet *)values;

- (void)insertObject:(MITMobiusResourceOwner *)value inOwnersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOwnersAtIndex:(NSUInteger)idx;
- (void)insertOwners:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOwnersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOwnersAtIndex:(NSUInteger)idx withObject:(MITMobiusResourceOwner *)value;
- (void)replaceOwnersAtIndexes:(NSIndexSet *)indexes withOwners:(NSArray *)values;
- (void)addOwnersObject:(MITMobiusResourceOwner *)value;
- (void)removeOwnersObject:(MITMobiusResourceOwner *)value;
- (void)addOwners:(NSOrderedSet *)values;
- (void)removeOwners:(NSOrderedSet *)values;

- (void)insertObject:(MITMobiusImage *)value inImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(MITMobiusImage *)value;
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)values;
- (void)addImagesObject:(MITMobiusImage *)value;
- (void)removeImagesObject:(MITMobiusImage *)value;
- (void)addImages:(NSOrderedSet *)values;
- (void)removeImages:(NSOrderedSet *)values;
@end
