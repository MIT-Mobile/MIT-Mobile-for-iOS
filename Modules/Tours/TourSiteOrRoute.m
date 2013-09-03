#import "TourSiteOrRoute.h"
#import "CoreDataManager.h"
#import "CampusTour.h"
#import "CampusTourSideTrip.h"
#import <CoreLocation/CoreLocation.h>

@implementation TourSiteOrRoute 

@dynamic longitude;
@dynamic latitude;
@dynamic path;
@dynamic type;
@dynamic sideTrips;
@dynamic nextComponent;
@dynamic previousComponent;
@dynamic tour;
@dynamic zoom;
@dynamic startLocations;
@dynamic sortOrder;

- (void)updateBody:(NSArray *)contents {
    for (CampusTourSideTrip *aTrip in self.sideTrips) {
        [CoreDataManager deleteObject:aTrip];
    }
    
    NSMutableString *bodyText = [NSMutableString string];
    for (NSDictionary *content in contents) {
        NSString *type = content[@"type"];
        if ([type isEqualToString:@"inline"]) {
            [bodyText appendString:content[@"html"]];
        } else if ([type isEqualToString:@"sidetrip"]) {
            CampusTourSideTrip *aTrip = [CoreDataManager insertNewObjectForEntityForName:CampusTourSideTripEntityName];
            aTrip.component = self;
            aTrip.componentID = content[@"id"];
            aTrip.title = content[@"title"];
            aTrip.body = content[@"html"];
            aTrip.photoURL = content[@"photo-url"];
            aTrip.audioURL = content[@"audio-url"];
            
            NSDictionary *coords = content[@"latlon"];
            aTrip.latitude = coords[@"latitude"];
            aTrip.longitude = coords[@"longitude"];
            
            NSString *placeholder = [NSString stringWithFormat:@"__SIDE_TRIP_%@__", aTrip.componentID];
            [bodyText appendString:placeholder];
        }
    }
    self.body = bodyText;
}

- (void)updatePath:(NSArray *)pathLocations {
    NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:[pathLocations count]];
    for (NSDictionary *coordinates in pathLocations) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[coordinates[@"latitude"] floatValue]
                                                           longitude:[coordinates[@"longitude"] floatValue]];
        [pathArray addObject:location];
    }
    [self saveArrayToPath:pathArray];
}

- (void)updateRouteWithInfo:(NSDictionary *)routeInfo {
    [self updateBody:routeInfo[@"content"]];
    [self updatePath:routeInfo[@"path"]];
    self.title = routeInfo[@"title"];
    self.photoURL = routeInfo[@"photo-url"];
    self.audioURL = routeInfo[@"audio-url"];
    self.zoom = routeInfo[@"zoom"];
}

- (NSArray *)pathAsArray {
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.path];
}

- (void)saveArrayToPath:(NSArray *)array {
	self.path = [NSKeyedArchiver archivedDataWithRootObject:array];
}

@end
