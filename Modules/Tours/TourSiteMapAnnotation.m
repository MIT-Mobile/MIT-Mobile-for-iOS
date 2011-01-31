#import "TourSiteMapAnnotation.h"
#import "TourSiteOrRoute.h"

@implementation TourSiteMapAnnotation

@synthesize site, subtitle, hasTransform, transform;

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake([self.site.latitude floatValue], [self.site.longitude floatValue]);
}

- (NSString *)title {
    return self.site.title;
}

- (void)dealloc {
    self.site = nil;
    self.subtitle = nil;
    [super dealloc];
}

@end
