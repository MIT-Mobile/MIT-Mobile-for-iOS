#import <CoreData/CoreData.h>


@interface ShuttleRouteCache :  NSManagedObject
{
}

@property (nonatomic, strong) NSString * routeID;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSNumber * interval;
@property (nonatomic, strong) NSNumber * isSafeRide;
@property (nonatomic, strong) NSString * summary;
@property (nonatomic, strong) NSSet* stops;
@property (nonatomic, strong) NSNumber * sortOrder;
 
@end

