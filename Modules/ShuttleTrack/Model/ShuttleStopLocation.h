#import <CoreData/CoreData.h>

@class ShuttleRouteStop;

@interface ShuttleStopLocation :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic, retain) NSSet* routeStops;

- (void)updateInfo:(NSDictionary *)stopInfo;
 
@end

