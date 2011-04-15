#import "CampusTourSideTrip.h"
#import "TourSiteOrRoute.h"

@implementation CampusTourSideTrip 

@dynamic component;
@dynamic latitude;
@dynamic longitude;

- (TourSiteOrRoute *)site {
    if([self.component.type isEqualToString:@"site"]) {
        return self.component;
    } else {
        return self.component.previousComponent;
    }
}
        
@end
