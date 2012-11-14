#import "MGSMapView.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@protocol MITMapRoute;
@class MITMapView;
@class MITMapAnnotationView;

@protocol MITMapViewDelegate<NSObject>
@optional
- (void)locateUserFailed:(MITMapView *)mapView;
- (void)mapViewRegionWillChange:(MITMapView*)mapView;
- (void)mapViewRegionDidChange:(MITMapView*)mapView;
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view;
- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views;
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch;
@end

@interface MGSMapView ()
@property (nonatomic, assign) id<MITMapViewDelegate> delegate;

@property CGFloat zoomLevel;
@property MKCoordinateRegion region;
@property CLLocationCoordinate2D centerCoordinate;

@property BOOL scrollEnabled;
@property BOOL showsUserLocation;
@property BOOL stayCenteredOnUserLocation;

@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) id<MKAnnotation> currentAnnotation;
@property (nonatomic, readonly) NSArray *routes;

- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate
               toPointToView:(UIView *)view;

- (void)fixateOnCampus;
- (void)refreshCallout;
- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (void)selectAnnotation:(id<MKAnnotation>)annotation;
- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter;
- (void)deselectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated;
- (void)addAnnotation:(id<MKAnnotation>)anAnnotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id<MKAnnotation>)annotation;
- (void)removeAllAnnotations:(BOOL)includeUserLocation;

- (void)addRoute:(id<MITMapRoute>)route;
- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route;
- (void)removeAllRoutes;
- (void)removeRoute:(id<MITMapRoute>) route;

- (void)addTileOverlay;
- (void)removeTileOverlay;
@end
