#import "TourSideTripMapAnnotation.h"
#import "CampusTourSideTrip.h"

@implementation TourSideTripMapAnnotation


- (void)setSideTrip:(CampusTourSideTrip *)aSidetrip {
    [sidetrip release];
    sidetrip = [aSidetrip retain];
    self.component = sidetrip;
    self.tourGeoLocation  = sidetrip;
}

- (CampusTourSideTrip *)sideTrip {
    return sidetrip;
}

- (void)dealloc {
    self.sideTrip = nil;
    [super dealloc];
}

@end
