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

@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSData * path;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet* sideTrips;
@property (nonatomic, retain) TourSiteOrRoute * nextComponent;
@property (nonatomic, retain) TourSiteOrRoute * previousComponent;
@property (nonatomic, retain) CampusTour * tour;
@property (nonatomic, retain) NSNumber * zoom;
@property (nonatomic, retain) NSSet* startLocations;
@property (nonatomic, retain) NSNumber * sortOrder;

@end


@interface TourSiteOrRoute (CoreDataGeneratedAccessors)
- (void)addSideTripsObject:(CampusTourSideTrip *)value;
- (void)removeSideTripsObject:(CampusTourSideTrip *)value;
- (void)addSideTrips:(NSSet *)value;
- (void)removeSideTrips:(NSSet *)value;

@end

