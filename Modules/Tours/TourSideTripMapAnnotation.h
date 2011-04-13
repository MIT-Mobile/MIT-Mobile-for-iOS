#import "TourMapAnnotation.h"

@class CampusTourSideTrip;

@interface TourSideTripMapAnnotation : TourMapAnnotation {

    CampusTourSideTrip *sidetrip;

}

@property (nonatomic, retain) CampusTourSideTrip *sideTrip;

@end
