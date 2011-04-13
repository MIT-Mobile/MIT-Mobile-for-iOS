#import "TourSideTripMapAnnotation.h"
#import "CampusTourSideTrip.h"

@implementation TourSideTripMapAnnotation


- (void)setSideTrip:(CampusTourSideTrip *)aSidetrip {
    [sidetrip release];
    sidetrip = [aSidetrip retain];
    self.tourGeoLocation  = sidetrip;
}

- (CampusTourSideTrip *)sideTrip {
    return sidetrip;
}

- (NSString *)title {
    return self.sideTrip.title;
}

- (void)dealloc {
    self.sideTrip = nil;
    [super dealloc];
}

@end
