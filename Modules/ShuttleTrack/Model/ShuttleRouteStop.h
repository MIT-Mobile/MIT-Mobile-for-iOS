#import <CoreData/CoreData.h>

@interface ShuttleRouteStop :  NSManagedObject  
{
}

@property (nonatomic, retain) id path;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSManagedObject * stopLocation;
@property (nonatomic, retain) NSManagedObject * route;

- (NSString *)stopID;
- (NSString *)routeID;

@end



