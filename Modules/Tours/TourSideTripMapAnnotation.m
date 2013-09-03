#import "TourSideTripMapAnnotation.h"
#import "CampusTourSideTrip.h"

@implementation TourSideTripMapAnnotation


- (void)setSideTrip:(CampusTourSideTrip *)aSidetrip {
    _sideTrip = aSidetrip;
    self.component = self.sideTrip;
    self.tourGeoLocation  = self.sideTrip;
}

@end
