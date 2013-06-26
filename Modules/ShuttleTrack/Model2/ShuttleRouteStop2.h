#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ShuttleRouteStop2 : NSManagedObject

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSManagedObject *stopLocation;
@property (nonatomic, retain) NSManagedObject *route;

- (NSString *)stopID;
- (NSString *)routeID;

@end
