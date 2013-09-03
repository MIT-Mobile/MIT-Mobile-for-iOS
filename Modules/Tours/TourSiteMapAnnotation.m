#import "TourSiteMapAnnotation.h"
#import "TourSiteOrRoute.h"

@implementation TourSiteMapAnnotation

- (void)setSite:(TourSiteOrRoute *)aSite {
    _site = nil;
    _site = aSite;
    self.component = self.site;
    self.tourGeoLocation = aSite;
}

@end
