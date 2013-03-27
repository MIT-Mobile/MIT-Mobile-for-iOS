#import <Foundation/Foundation.h>
#import "MGSMapView.h"

@class AGSMapView;
@class AGSGraphic;
@class AGSLocationDisplay;
@class MGSLayer;

@protocol MGSAnnotation;

@interface MGSMapView (AGSMapViewCalloutDelegate)
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic;
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForLocationDisplay:(AGSLocationDisplay *)ld;
- (void)mapViewWillDismissCallout:(AGSMapView *)mapView;
- (void)mapViewDidDismissCallout:(AGSMapView *)mapView;
@end

@interface MGSMapView (AGSMapViewLayerDelegate)
- (void)mapViewDidLoad:(AGSMapView *)mapView;
@end

@interface MGSMapView (AGSMapViewTouchDelegate)
- (BOOL)mapView:(AGSMapView*)mapView shouldProcessClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint;
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapViewDidCancelTapAndHold:(AGSMapView *)mapView;
@end

@interface MGSMapView (AGSLayerDelegate)
- (void)layer:(AGSLayer *)loadedLayer didInitializeSpatialReferenceStatus:(BOOL)srStatusValid;
- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error;
@end

@interface MGSMapView (AGSCalloutDelegate)
- (void)didClickAccessoryButtonForCallout:(AGSCallout *)callout;
@end

@interface MGSMapView (AGSLocationDisplayDataSourceDelegate)
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
                 didFailWithError:(NSError*)error;
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
             didUpdateWithHeading:(double)heading;
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
            didUpdateWithLocation:(AGSLocation*)location;
- (void)locationDisplayDataSourceStarted:(id<AGSLocationDisplayDataSource>)dataSource;
- (void)locationDisplayDataSourceStopped:(id<AGSLocationDisplayDataSource>)dataSource;
@end

@interface MGSMapView (DelegateHelpers)
- (BOOL)shouldShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
- (void)calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;
- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)didDismissCalloutForAnnotation:(id<MGSAnnotation>)annotation;

- (void)didFinishLoadingMapView;
- (void)willAddLayer:(MGSLayer *)layer;
- (void)didAddLayer:(MGSLayer *)layer;
- (void)willRemoveLayer:(MGSLayer *)layer;
- (void)didRemoveLayer:(MGSLayer *)layer;

- (void)userLocationDidUpdate:(CLLocation*)location;
- (void)userLocationUpdateFailedWithError:(NSError*)error;
@end