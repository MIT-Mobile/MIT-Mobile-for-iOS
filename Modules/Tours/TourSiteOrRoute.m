#import "TourSiteOrRoute.h"
#import "CoreDataManager.h"
#import "CampusTour.h"
#import "CampusTourSideTrip.h"
#import <CoreLocation/CoreLocation.h>
#import "ToursDataManager.h"

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

- (void)updateBody:(NSArray *)contents withTourID:(NSString *)tourID{
    for (CampusTourSideTrip *aTrip in self.sideTrips) {
        [CoreDataManager deleteObject:aTrip];
    }
    
    NSMutableString *bodyText = [NSMutableString string];
    for (NSDictionary *content in contents) {
        NSString *type = [content objectForKey:@"type"];
        if ([type isEqualToString:@"inline"]) {
            [bodyText appendString:[content objectForKey:@"html"]];
        } else if ([type isEqualToString:@"sidetrip"]) {
            CampusTourSideTrip *aTrip = [CoreDataManager insertNewObjectForEntityForName:CampusTourSideTripEntityName];
            aTrip.component = self;
            aTrip.componentID = [content objectForKey:@"id"];
            aTrip.title = [content objectForKey:@"title"];
            aTrip.body = [content objectForKey:@"html"];
            aTrip.photoURL = [ToursDataManager getPhotoUrl:[content objectForKey:@"photo-id"] withTourID:tourID];
            aTrip.photoThumbnailURL = [ToursDataManager getPhotoUrl:[content objectForKey:@"thumbnail156-id"] withTourID:tourID];
//            aTrip.audioURL = [content objectForKey:@"audio-url"];
            aTrip.audioURL = [ToursDataManager getSoundUrl:[content objectForKey:@"audio-id"] withTourID:tourID];
            
            NSDictionary *coords = [content objectForKey:@"latlon"];
            aTrip.latitude = [NSNumber numberWithFloat:[[coords objectForKey:@"latitude"] floatValue]];
            aTrip.longitude = [NSNumber numberWithFloat:[[coords objectForKey:@"longitude"] floatValue]];
            
            NSString *placeholder = [NSString stringWithFormat:@"__SIDE_TRIP_%@__", aTrip.componentID];
            [bodyText appendString:placeholder];
        }
    }
    self.body = bodyText;
}

- (void)updatePath:(NSArray *)pathLocations {
    NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:[pathLocations count]];
    for (NSDictionary *coordinates in pathLocations) {
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:[[coordinates objectForKey:@"latitude"] floatValue]
                                                           longitude:[[coordinates objectForKey:@"longitude"] floatValue]] autorelease];
        [pathArray addObject:location];
    }
    [self saveArrayToPath:pathArray];
}

- (void)updateRouteWithInfo:(NSDictionary *)routeInfo withTourID:(NSString *)tourID{
    [self updateBody:[routeInfo objectForKey:@"content"] withTourID:tourID];
    [self updatePath:[routeInfo objectForKey:@"path"]];
    self.title = [routeInfo objectForKey:@"title"];
    self.photoURL = [ToursDataManager getPhotoUrl:[routeInfo objectForKey:@"photo-id"] withTourID:tourID];
    self.photoThumbnailURL = [ToursDataManager getPhotoUrl:[routeInfo objectForKey:@"thumbnail156-id"] withTourID:tourID];
//    self.audioURL = [routeInfo objectForKey:@"audio-url"];
    self.audioURL = [ToursDataManager getSoundUrl:[routeInfo objectForKey:@"audio-id"] withTourID:tourID];
    self.zoom = [NSNumber numberWithInt:[[routeInfo objectForKey:@"zoom"] floatValue]];
}

- (NSArray *)pathAsArray {
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.path];
}

- (void)saveArrayToPath:(NSArray *)array {
	self.path = [NSKeyedArchiver archivedDataWithRootObject:array];
}

@end
