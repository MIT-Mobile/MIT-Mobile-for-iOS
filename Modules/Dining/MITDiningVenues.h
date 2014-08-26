#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningDining, MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningVenues : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) MITDiningDining *dining;
@property (nonatomic, retain) NSOrderedSet *house;
@property (nonatomic, retain) NSOrderedSet *retail;
@end

@interface MITDiningVenues (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningHouseVenue *)value inHouseAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHouseAtIndex:(NSUInteger)idx;
- (void)insertHouse:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHouseAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHouseAtIndex:(NSUInteger)idx withObject:(MITDiningHouseVenue *)value;
- (void)replaceHouseAtIndexes:(NSIndexSet *)indexes withHouse:(NSArray *)values;
- (void)addHouseObject:(MITDiningHouseVenue *)value;
- (void)removeHouseObject:(MITDiningHouseVenue *)value;
- (void)addHouse:(NSOrderedSet *)values;
- (void)removeHouse:(NSOrderedSet *)values;
- (void)insertObject:(MITDiningRetailVenue *)value inRetailAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRetailAtIndex:(NSUInteger)idx;
- (void)insertRetail:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRetailAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRetailAtIndex:(NSUInteger)idx withObject:(MITDiningRetailVenue *)value;
- (void)replaceRetailAtIndexes:(NSIndexSet *)indexes withRetail:(NSArray *)values;
- (void)addRetailObject:(MITDiningRetailVenue *)value;
- (void)removeRetailObject:(MITDiningRetailVenue *)value;
- (void)addRetail:(NSOrderedSet *)values;
- (void)removeRetail:(NSOrderedSet *)values;
@end
