#import <Foundation/Foundation.h>

@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSMapViewDelegate <NSObject>
@optional
- (void)didFinishLoadingMapView:(MGSMapView*)mapView;
- (void)mapView:(MGSMapView*)mapView didFailWithError:(NSError*)error;

- (BOOL)mapView:(MGSMapView*)mapView shouldShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView willShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (UIView*)mapView:(MGSMapView*)mapView calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView didShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView didDismissCalloutForAnnotation:(id<MGSAnnotation>)annotation;

- (void)mapView:(MGSMapView*)mapView didReceiveTapAtCoordinate:(CLLocationCoordinate2D)coordinate
    screenPoint:(CGPoint)screenPoint;

- (void)mapView:(MGSMapView*)mapView willAddLayer:(MGSLayer*)layer;
- (void)mapView:(MGSMapView*)mapView didAddLayer:(MGSLayer*)layer;

- (void)mapView:(MGSMapView*)mapView willRemoveLayer:(MGSLayer*)layer;
- (void)mapView:(MGSMapView*)mapView didRemoveLayer:(MGSLayer*)layer;

- (void)mapView:(MGSMapView*)mapView userLocationDidUpdate:(CLLocation*)location;
- (void)mapView:(MGSMapView*)mapView userLocationUpdateFailedWithError:(NSError*)error;
@end
