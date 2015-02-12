#import <MapKit/MapKit.h>

// MITCalloutMapView
// The purpose of this subclass is to override the touch-handling behavior of MKMapView
// so that our annotation callouts can receive touches. The implementation was taken directly
// from the SMCalloutView sample project code.
@class MITCalloutView;
@interface MITCalloutMapView : MKMapView
@property (nonatomic, strong) MITCalloutView *mitCalloutView;
@end
