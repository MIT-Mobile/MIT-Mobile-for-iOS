#import <Foundation/Foundation.h>

@class MGSMapView;
@protocol MGSAnnotation;

@protocol MGSMapViewDelegate <NSObject>
- (void)didFinishLoadingMapView:(MGSMapView*)mapView;
- (void)mapView:(MGSMapView*)mapView willShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView didShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapView:(MGSMapView*)mapView calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;
@end
