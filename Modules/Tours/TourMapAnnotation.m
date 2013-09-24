#import "TourMapAnnotation.h"
#import "TourGeoLocation.h"
#import "TourComponent.h"

@implementation TourMapAnnotation

@synthesize component, subtitle, transform, tourGeoLocation;

- (id)init {
    self = [super init];
    
    if (self) {
        self.transform = CGAffineTransformIdentity;
    }
    
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(
        [[tourGeoLocation latitude] floatValue],
        [[tourGeoLocation longitude] floatValue]);
}


- (NSString *) title {
    return self.component.title;
}

- (void)dealloc {
    self.component = nil;
    self.subtitle = nil;
    [super dealloc];
}

@end
