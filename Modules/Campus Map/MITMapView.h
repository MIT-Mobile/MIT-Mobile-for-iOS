#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MITMapAnnotationView.h"
#import "MITMapAnnotationCalloutView.h"
#import "MITMapScrollView.h"
#import "MITProjection.h"
#import "MITMobileWebAPI.h"
#import "MITMapRoute.h"

@class MapLevel;
@class MITMapUserLocation;
@class MITMapView;
@class MITMapSearchResultAnnotation;
@class RouteView;
@class GridLayer; // not used
@class MapTileOverlay;

@protocol MITMapViewDelegate<NSObject>

@optional

// MKMapView-like methods
- (void)mapView:(MITMapView *)mapView annotationSelected:(id <MKAnnotation>)annotation;
- (void)annotationCalloutDidDisappear:(MITMapView *)mapView; // TODO: this doesn't get called
- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)location;
- (void)locateUserFailed:(MITMapView *)mapView;

// MKMapViewDelegate forwarding
- (MKOverlayView *)mapView:(MITMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay;
- (void)mapViewRegionWillChange:(MITMapView*)mapView;
- (void)mapViewRegionDidChange:(MITMapView*)mapView;
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view;
- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views;

// any touch on the map will invoke this.
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch;

@end


@interface MITMapView : UIView <MKMapViewDelegate> {

    MKMapView *_mapView;
	BOOL _stayCenteredOnUserLocation;
	id<MITMapViewDelegate> _mapDelegate;

	NSMutableArray* _routes;
    NSMutableDictionary *_routePolylines; // kluge way to associate routes with polylines

	MITMapAnnotationCalloutView * customCallOutView;
	
	// didDeselectAnnotationView is always triggered after didSelectAnnotationView.
	// This BOOL value helps when selecting another Annotation while one is already displaying a custom callout
	BOOL addRemoveCustomAnnotationCombo;
    
    MapTileOverlay *tileOverlay;
}

// message sent by MITMKProjection to let us know we can add tiles
- (void)enableProjectedFeatures;

- (void)fixateOnCampus;

@property (nonatomic, assign) id<MITMapViewDelegate> delegate;
@property (nonatomic, retain) MKMapView *mapView;
@property BOOL stayCenteredOnUserLocation;
@property CGFloat zoomLevel;

#pragma mark MKMapView forwarding

//- (void)didUpdateUserLocation:(MKUserLocation *)userLocation;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated;
- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view;
- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(UIView *)view;

@property MKCoordinateRegion region;
@property CLLocationCoordinate2D centerCoordinate;
@property BOOL scrollEnabled;
@property BOOL showsUserLocation;
@property (readonly) MKUserLocation *userLocation;

#pragma mark Annotations

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)refreshCallout;
- (void)adjustCustomCallOut;
- (void)positionAnnotationView:(MITMapAnnotationView*)annotationView;
- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (void)selectAnnotation:(id<MKAnnotation>)annotation;
- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter;
- (void)deselectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated;
- (void)addAnnotation:(id<MKAnnotation>)anAnnotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id<MKAnnotation>)annotation;
- (void)removeAllAnnotations:(BOOL)includeUserLocation;

@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) id<MKAnnotation> currentAnnotation;

#pragma mark Overlays

- (void)addRoute:(id<MITMapRoute>)route;
- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route;
- (void)removeAllRoutes;
- (void)removeRoute:(id<MITMapRoute>) route;

- (void)addTileOverlay;
- (void)removeTileOverlay;
- (void)removeAllOverlays;

@property (nonatomic, readonly) NSArray *routes;

@end
