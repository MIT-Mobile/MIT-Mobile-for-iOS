#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MITMapRoute.h"

@class MITMapView;
@class MITMapSearchResultAnnotation;
@class MGSMapView;
@class MITMapAnnotationView;

DEPRECATED_ATTRIBUTE
@protocol MITMapViewDelegate <NSObject>
@optional
- (void)mapViewDidFinishLoading:(MITMapView*)mapView;

// MKMapView-like methods
- (void)mapView:(MITMapView *)mapView annotationSelected:(id <MKAnnotation>)annotation;
- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)location;
- (void)locateUserFailed:(MITMapView *)mapView;

// MKMapViewDelegate forwarding
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view;
- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views;

- (void)mapViewRegionWillChange:(MITMapView*)mapView;
- (void)mapViewRegionDidChange:(MITMapView*)mapView;

// any touch on the map will invoke this.
- (void)mapView:(MITMapView *)mapView wasTouched:(CGPoint)screenPoint;
@end


DEPRECATED_ATTRIBUTE
@interface MITMapView : UIView
@property (nonatomic, weak) id<MITMapViewDelegate> delegate;
@property (nonatomic, readonly, weak) MGSMapView *mapView;
@property (nonatomic) BOOL stayCenteredOnUserLocation;
@property (nonatomic) CGFloat zoomLevel;
@property (nonatomic) CLLocationDistance minimumRegionSize;

#pragma mark MKMapView forwarding
@property (nonatomic) CLLocationCoordinate2D centerCoordinate;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated;

- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view;

@property MKCoordinateRegion region;
@property BOOL scrollEnabled;
@property BOOL showsUserLocation;

#pragma mark Annotations

// programmatically select and recenter on an annotation. Must be in our list of annotations
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

- (MITMapAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation;

@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly, weak) id<MKAnnotation> currentAnnotation;

#pragma mark Overlays

- (void)addRoute:(id<MITMapRoute>)route;
- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route;
- (void)removeAllRoutes;
- (void)removeRoute:(id<MITMapRoute>) route;

- (void)addTileOverlay; // NOP
- (void)removeTileOverlay; // NOP
- (void)removeAllOverlays; // NOP

@property (nonatomic, readonly) NSArray *routes;

@end
