#import "MITToursTiledMapView.h"
#import "MITCalloutMapView.h"

@implementation MITToursTiledMapView

- (MKMapView *)createMapView
{
    return [[MITCalloutMapView alloc] initWithFrame:self.frame];
}

@end
