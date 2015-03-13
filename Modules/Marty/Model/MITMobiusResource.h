#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMobiusObject.h"
#import <MapKit/MapKit.h>

@class MITMobiusCategory, MITMobiusResourceAttribute, MITMobiusResourceOwner, MITMobiusResourceSearch, MITMobiusTemplate, MITMartyType;

@interface MITMobiusResource : MITMobiusObject <MKAnnotation>

@property (nonatomic, retain) NSString * dlc;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * reservable;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSOrderedSet *attributes;
@property (nonatomic, retain) MITMobiusCategory *category;
@property (nonatomic, retain) NSOrderedSet *owners;
@property (nonatomic, retain) NSSet *searches;
@property (nonatomic, retain) MITMobiusTemplate *template;
@property (nonatomic, retain) MITMartyType *type;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@interface MITMobiusResource (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMobiusResourceAttribute *)value inAttributesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttributesAtIndex:(NSUInteger)idx;
- (void)insertAttributes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttributesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttributesAtIndex:(NSUInteger)idx withObject:(MITMobiusResourceAttribute *)value;
- (void)replaceAttributesAtIndexes:(NSIndexSet *)indexes withAttributes:(NSArray *)values;
- (void)addAttributesObject:(MITMobiusResourceAttribute *)value;
- (void)removeAttributesObject:(MITMobiusResourceAttribute *)value;
- (void)addAttributes:(NSOrderedSet *)values;
- (void)removeAttributes:(NSOrderedSet *)values;
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
- (void)addSearchesObject:(MITMobiusResourceSearch *)value;
- (void)removeSearchesObject:(MITMobiusResourceSearch *)value;
- (void)addSearches:(NSSet *)values;
- (void)removeSearches:(NSSet *)values;

@end
