#import "TourSiteMapAnnotation.h"
#import "TourSiteOrRoute.h"

@implementation TourSiteMapAnnotation

- (void)setSite:(TourSiteOrRoute *)aSite {
    [site release];
    site = nil;
    site = [aSite retain];
    self.component = site;
    self.tourGeoLocation = aSite;
}

- (TourSiteOrRoute *)site {
    return site;
}

- (void)dealloc {
    site = nil;
    [super dealloc];
}

@end
