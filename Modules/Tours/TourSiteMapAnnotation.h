#import "TourMapAnnotation.h"

@class TourSiteOrRoute;

@interface TourSiteMapAnnotation : TourMapAnnotation {
    TourSiteOrRoute *site;
}

@property (nonatomic, retain) TourSiteOrRoute *site;

@end
