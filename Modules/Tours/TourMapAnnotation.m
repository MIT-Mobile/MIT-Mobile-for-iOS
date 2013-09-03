#import "TourMapAnnotation.h"
#import "TourGeoLocation.h"
#import "TourComponent.h"

@implementation TourMapAnnotation

- (id)init {
    self = [super init];
    
    if (self) {
        self.transform = CGAffineTransformIdentity;
    }
    
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(
        [[self.tourGeoLocation latitude] floatValue],
        [[self.tourGeoLocation longitude] floatValue]);
}


- (NSString *) title {
    return self.component.title;
}

@end
