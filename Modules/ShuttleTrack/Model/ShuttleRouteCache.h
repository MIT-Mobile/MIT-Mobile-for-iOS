#import <CoreData/CoreData.h>


@interface ShuttleRouteCache :  NSManagedObject
{
}

@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSNumber * isSafeRide;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSSet* stops;
@property (nonatomic, retain) NSNumber * sortOrder;
 
@end

