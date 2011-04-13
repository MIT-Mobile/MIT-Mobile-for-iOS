#import "TourMapAnnotation.h"
#import "TourGeoLocation.h"

@implementation TourMapAnnotation

@synthesize title, subtitle, hasTransform, transform, tourGeoLocation;

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(
        [[tourGeoLocation latitude] floatValue],
        [[tourGeoLocation longitude] floatValue]);
}


- (void)dealloc {
    self.title = nil;
    self.subtitle = nil;
    [super dealloc];
}

@end
