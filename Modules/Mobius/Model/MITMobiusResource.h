#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute, MITMobiusCategory, MITMobiusResourceAttributeValueSet, MITMobiusResourceDLC, MITMobiusResourceHours, MITMobiusResourceOwner, MITMobiusType;

@interface MITMobiusResource : MITManagedObject <MITMappedObject,MKAnnotation>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * reservable;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSOrderedSet *attributes;
@property (nonatomic, retain) NSOrderedSet *attributeValues;
@property (nonatomic, retain) MITMobiusCategory *category;
@property (nonatomic, retain) MITMobiusResourceDLC *dlc;
@property (nonatomic, retain) NSSet *hours;
@property (nonatomic, retain) NSOrderedSet *owners;
@property (nonatomic, retain) NSManagedObject *roomset;
@property (nonatomic, retain) MITMobiusType *type;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@interface MITMobiusResource (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusAttribute *)value inAttributesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttributesAtIndex:(NSUInteger)idx;
- (void)insertAttributes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttributesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttributesAtIndex:(NSUInteger)idx withObject:(MITMobiusAttribute *)value;
- (void)replaceAttributesAtIndexes:(NSIndexSet *)indexes withAttributes:(NSArray *)values;
- (void)addAttributesObject:(MITMobiusAttribute *)value;
- (void)removeAttributesObject:(MITMobiusAttribute *)value;
- (void)addAttributes:(NSOrderedSet *)values;
- (void)removeAttributes:(NSOrderedSet *)values;
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
@end
