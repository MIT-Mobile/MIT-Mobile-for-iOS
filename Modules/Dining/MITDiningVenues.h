#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningHouseVenue, MITDiningRetailVenue;

@interface MITDiningVenues : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSSet *house;
@property (nonatomic, retain) NSSet *retail;
@end

@interface MITDiningVenues (CoreDataGeneratedAccessors)

- (void)addHouseObject:(MITDiningHouseVenue *)value;
- (void)removeHouseObject:(MITDiningHouseVenue *)value;
- (void)addHouse:(NSSet *)values;
- (void)removeHouse:(NSSet *)values;

- (void)addRetailObject:(MITDiningRetailVenue *)value;
- (void)removeRetailObject:(MITDiningRetailVenue *)value;
- (void)addRetail:(NSSet *)values;
- (void)removeRetail:(NSSet *)values;

@end
