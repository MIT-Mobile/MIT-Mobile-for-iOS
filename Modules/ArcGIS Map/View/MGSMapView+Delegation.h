#import <Foundation/Foundation.h>
#import "MGSMapView.h"

@class AGSMapView;
@class AGSGraphic;
@class AGSLocationDisplay;
@class MGSLayer;

@protocol MGSAnnotation;

@interface MGSMapView (Delegation)
#pragma mark AGSMapViewCalloutDelegate
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic;
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForLocationDisplay:(AGSLocationDisplay *)ld;
- (void)mapViewWillDismissCallout:(AGSMapView *)mapView;
- (void)mapViewDidDismissCallout:(AGSMapView *)mapView;

#pragma mark AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *)mapView;

#pragma mark AGSMapViewTouchDelegate
- (BOOL)mapView:(AGSMapView*)mapView shouldProcessClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint;
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics;
- (void)mapViewDidCancelTapAndHold:(AGSMapView *)mapView;

#pragma mark AGSLayerDelegate
- (void)layer:(AGSLayer *)loadedLayer didInitializeSpatialReferenceStatus:(BOOL)srStatusValid;
- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error;

#pragma mark AGSCalloutDelegate
- (void)didClickAccessoryButtonForCallout:(AGSCallout *)callout;

#pragma mark AGSLocationDisplayDataSourceDelegate
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
                 didFailWithError:(NSError*)error;
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
             didUpdateWithHeading:(double)heading;
- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource
            didUpdateWithLocation:(AGSLocation*)location;
- (void)locationDisplayDataSourceStarted:(id<AGSLocationDisplayDataSource>)dataSource;
- (void)locationDisplayDataSourceStopped:(id<AGSLocationDisplayDataSource>)dataSource;

#pragma mark MGSLayerManagerDelegate
- (void)layerManagerDidSynchronizeAnnotations:(MGSLayerManager*)layerManager;
@end