#import <Foundation/Foundation.h>

@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSMapViewDelegate <NSObject>
@optional
- (void)didFinishLoadingMapView:(MGSMapView*)mapView;

- (void)mapView:(MGSMapView*)mapView willShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView didShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;

- (void)mapView:(MGSMapView*)mapView willAddLayer:(MGSLayer*)layer;
- (void)mapView:(MGSMapView*)mapView didAddLayer:(MGSLayer*)layer;

- (void)mapView:(MGSMapView*)mapView willRemoveLayer:(MGSLayer*)layer;
- (void)mapView:(MGSMapView*)mapView didRemoveLayer:(MGSLayer*)layer;
@end
