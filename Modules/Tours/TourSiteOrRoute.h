#import <CoreData/CoreData.h>
#import "TourComponent.h"
#import "TourGeoLocation.h"

@class CampusTour;
@class CampusTourSideTrip;

@interface TourSiteOrRoute : TourComponent <TourGeoLocation>
{
}

- (void)updateBody:(NSArray *)contents;
- (void)updatePath:(NSArray *)pathLocations;
- (NSArray *)pathAsArray;
- (void)saveArrayToPath:(NSArray *)array;
- (void)updateRouteWithInfo:(NSDictionary *)routeInfo;

@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, copy) NSData * path;
@property (nonatomic, copy) NSString * type;
@property (nonatomic, copy) NSSet* sideTrips;
@property (nonatomic, strong) TourSiteOrRoute * nextComponent;
@property (nonatomic, strong) TourSiteOrRoute * previousComponent;
@property (nonatomic, strong) CampusTour * tour;
@property (nonatomic, strong) NSNumber * zoom;
@property (nonatomic, copy) NSSet* startLocations;
@property (nonatomic, strong) NSNumber * sortOrder;

@end


@interface TourSiteOrRoute (CoreDataGeneratedAccessors)
- (void)addSideTripsObject:(CampusTourSideTrip *)value;
- (void)removeSideTripsObject:(CampusTourSideTrip *)value;
- (void)addSideTrips:(NSSet *)value;
- (void)removeSideTrips:(NSSet *)value;

@end

