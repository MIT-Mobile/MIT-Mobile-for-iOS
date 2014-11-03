#import "MITToursTiledMapView.h"
#import "MITToursCalloutMapView.h"

@implementation MITToursTiledMapView

- (MKMapView *)createMapView
{
    return [[MITToursCalloutMapView alloc] initWithFrame:self.frame];
}

@end
