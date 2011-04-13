#import "TourSiteMapAnnotation.h"
#import "TourSiteOrRoute.h"

@implementation TourSiteMapAnnotation

- (void)setSite:(TourSiteOrRoute *)aSite {
    [site release];
    site = nil;
    site = [aSite retain];
    self.tourGeoLocation = aSite;
}

- (TourSiteOrRoute *)site {
    return site;
}

- (NSString *)title {
    return self.site.title;
}

- (void)dealloc {
    site = nil;
    [super dealloc];
}

@end
