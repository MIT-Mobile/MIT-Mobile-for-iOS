#import <CoreData/CoreData.h>

@class ShuttleRouteStop;

@interface ShuttleStopLocation :  NSManagedObject  
{
}

@property (nonatomic, strong) NSString * stopID;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSSet* routeStops;

- (void)updateInfo:(NSDictionary *)stopInfo;
 
@end

