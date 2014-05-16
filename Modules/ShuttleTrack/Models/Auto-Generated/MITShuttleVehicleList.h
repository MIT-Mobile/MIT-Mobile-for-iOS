//
//  MITShuttleVehicleList.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/16/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITShuttleVehicle;

@interface MITShuttleVehicleList : NSManagedObject

@property (nonatomic, retain) NSString * agency;
@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * routeTitle;
@property (nonatomic, retain) NSString * routeURL;
@property (nonatomic, retain) NSOrderedSet *vehicles;
@end

@interface MITShuttleVehicleList (CoreDataGeneratedAccessors)

- (void)insertObject:(MITShuttleVehicle *)value inVehiclesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromVehiclesAtIndex:(NSUInteger)idx;
- (void)insertVehicles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeVehiclesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInVehiclesAtIndex:(NSUInteger)idx withObject:(MITShuttleVehicle *)value;
- (void)replaceVehiclesAtIndexes:(NSIndexSet *)indexes withVehicles:(NSArray *)values;
- (void)addVehiclesObject:(MITShuttleVehicle *)value;
- (void)removeVehiclesObject:(MITShuttleVehicle *)value;
- (void)addVehicles:(NSOrderedSet *)values;
- (void)removeVehicles:(NSOrderedSet *)values;
@end
