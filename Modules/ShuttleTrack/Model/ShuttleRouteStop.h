#import <CoreData/CoreData.h>

@interface ShuttleRouteStop :  NSManagedObject  
{
}

@property (nonatomic, strong) id path;
@property (nonatomic, strong) NSNumber * order;
@property (nonatomic, strong) NSManagedObject * stopLocation;
@property (nonatomic, strong) NSManagedObject * route;

- (NSString *)stopID;
- (NSString *)routeID;

@end



