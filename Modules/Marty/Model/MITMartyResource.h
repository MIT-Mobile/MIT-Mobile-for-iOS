#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMartyObject.h"

@class MITMartyCategory, MITMartyResourceAttribute, MITMartyResourceOwner, MITMartyResourceSearch, MITMartyTemplate, MITMartyType;

@interface MITMartyResource : MITMartyObject

@property (nonatomic, retain) NSString * dlc;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * reservable;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSOrderedSet *attributes;
@property (nonatomic, retain) MITMartyCategory *category;
@property (nonatomic, retain) NSOrderedSet *owners;
@property (nonatomic, retain) NSSet *searches;
@property (nonatomic, retain) MITMartyTemplate *template;
@property (nonatomic, retain) MITMartyType *type;
@end

@interface MITMartyResource (CoreDataGeneratedAccessors)

- (void)insertObject:(MITMartyResourceAttribute *)value inAttributesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttributesAtIndex:(NSUInteger)idx;
- (void)insertAttributes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttributesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttributesAtIndex:(NSUInteger)idx withObject:(MITMartyResourceAttribute *)value;
- (void)replaceAttributesAtIndexes:(NSIndexSet *)indexes withAttributes:(NSArray *)values;
- (void)addAttributesObject:(MITMartyResourceAttribute *)value;
- (void)removeAttributesObject:(MITMartyResourceAttribute *)value;
- (void)addAttributes:(NSOrderedSet *)values;
- (void)removeAttributes:(NSOrderedSet *)values;
- (void)insertObject:(MITMartyResourceOwner *)value inOwnersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOwnersAtIndex:(NSUInteger)idx;
- (void)insertOwners:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOwnersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOwnersAtIndex:(NSUInteger)idx withObject:(MITMartyResourceOwner *)value;
- (void)replaceOwnersAtIndexes:(NSIndexSet *)indexes withOwners:(NSArray *)values;
- (void)addOwnersObject:(MITMartyResourceOwner *)value;
- (void)removeOwnersObject:(MITMartyResourceOwner *)value;
- (void)addOwners:(NSOrderedSet *)values;
- (void)removeOwners:(NSOrderedSet *)values;
- (void)addSearchesObject:(MITMartyResourceSearch *)value;
- (void)removeSearchesObject:(MITMartyResourceSearch *)value;
- (void)addSearches:(NSSet *)values;
- (void)removeSearches:(NSSet *)values;

@end
