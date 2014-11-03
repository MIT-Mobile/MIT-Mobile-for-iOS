#import <MapKit/MapKit.h>
#import "SMCalloutView.h"

// MITToursCalloutMapView
// The purpose of this subclass is to override the touch-handling behavior of MKMapView
// so that our annotation callouts can receive touches. The implementation was taken directly
// from the SMCalloutView sample project code.

@interface MITToursCalloutMapView : MKMapView

@property (nonatomic, strong) SMCalloutView *calloutView;

@end
