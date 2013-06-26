#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShuttleRouteStop2;

@interface ShuttleStopLocation2 : NSManagedObject
{
}

@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSSet *routeStops;

- (void)updateInfo:(NSDictionary *)stopInfo;

@end
