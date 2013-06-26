#import <CoreData/CoreData.h>


@interface ShuttleRouteCache2 : NSManagedObject
{
}

@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) id path;
@property (nonatomic, retain) NSSet *stops;
@property (nonatomic, retain) NSNumber *sortOrder;

@end
