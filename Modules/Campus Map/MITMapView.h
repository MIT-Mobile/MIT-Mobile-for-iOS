
#import <UIKit/UIKit.h>

#import "MapTileCache.h"
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
@class GridLayer;


@protocol MITMapViewDelegate<NSObject>

@optional

- (void)mapViewRegionWillChange:(MITMapView*)mapView ;

-(void) mapViewRegionDidChange:(MITMapView*)mapView;

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;

- (void)mapView:(MITMapView *)mapView annotationViewcalloutAccessoryTapped:(MITMapAnnotationCalloutView *)view; 

// any touch on the map will invoke this.  
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch;

- (void)annotationSelected:(id <MKAnnotation>)annotation;

- (void)annotationCalloutDidDisappear;

- (void)locateUserFailed;

@end

@interface MITMapView : UIView <UIScrollViewDelegate, CLLocationManagerDelegate>{

	NSArray* _mapLevels;
	
	UIView* _mapContentView;
	
	MITMapScrollView* _scrollView;
	
	CATiledLayer* _tiledLayer;
	
	CALayer* _locationLayer;								// a layer for the blue dot and animated circles
	
	UIImageView* _locationView;								// this is the blue dot that marks your current location
	
	CAShapeLayer* _locationAccuracyCircleLayer;				// this is the animated circle that grows & shrinks to tell you how accurate your location is
	CAShapeLayer* _radiationLayer1;
	CAShapeLayer* _radiationLayer2;							// these two layers create the radiation bwoop
	
	BOOL _animationIsBouncing;								// the bounce animation (when accuracy is poor) shouldn't be interrupted by another bounce animation
	BOOL _animationIsRadiating;								// the radiation animation (when accuracy is good) shouldn't be interrupted by another radiation animation
	BOOL _locationCircleIsMinimized;						// the magic blue circle is hidden under the dot. we need to know this if they zoom while it's hidden.
	
	CLLocation* _lastLocation;								// this allows us to redraw the accuracy circle for different zoom scales
		
	BOOL _showsUserLocation;
	
	BOOL _stayCenteredOnUserLocation;
	
	CLLocationManager* _locationManager;
	
	MITMapUserLocation* _userLocationAnnotation;
	
	id<MITMapViewDelegate> _mapDelegate;
	
	NSMutableArray* _annotations;
	
	NSMutableArray* _annotationViews;
	NSMutableArray* _annotationShadowViews;					// holds the annotations shadows while they drop so they can be removed 
	NSTimer* _pinDropTimer;									// this triggers pin drop animation when it fires so pins fall in series
	BOOL _shouldNotDropPins;								// if false, pins are animated onto map.  shouldNotDropPins is set to true for 
																// MITMapDetailViewController, RouteMapViewController, and ShuttleStopViewController.
	
	NSMutableArray* _routes;
		
	// dictionary of uiimageviews used for preloading some map data. These views 
	// should be removed as the data actually loads. 
	NSMutableDictionary* _preloadedLayers;
	
	MITMapAnnotationCalloutView *_currentCallout;
	
	RouteView* _routeView;
	
    // default view of the map.
    CLLocationCoordinate2D _initialLocation;
    CGFloat _initialZoom;
    
	// NorthWest and SouthEast corners of the map
	CLLocationCoordinate2D _nw;
	CLLocationCoordinate2D _se;
	
	// flag indicating whether the user denied access to CLLocationManager
	BOOL _locationDenied;
	BOOL _displayedLocationDenied;
	BOOL _receivedFirstLocationDenied;

}

@property (nonatomic, retain) NSArray* mapLevels;
@property (nonatomic, assign) id<MITMapViewDelegate> delegate;
@property CLLocationCoordinate2D centerCoordinate;
@property (nonatomic, readonly) MITMapUserLocation* userLocation;

@property BOOL showsUserLocation;
@property BOOL stayCenteredOnUserLocation;
@property BOOL scrollEnabled;

@property (readonly) CGFloat zoomLevel;
@property MKCoordinateRegion region;

@property BOOL shouldNotDropPins;


// get the unscaled screen coordinate for a location
-(CGPoint) unscaledScreenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

-(CGPoint) screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

// get the geographic coordinate for a point on our map
-(CLLocationCoordinate2D) coordinateForScreenPoint:(CGPoint) point;

-(void) setCenterCoordinate:(CLLocationCoordinate2D) coordinate animated:(BOOL)animated;

-(void) hideCallout;

-(void) refreshCallout;

-(void) positionAnnotationView:(MITMapAnnotationView *)annotationView;

// region helper functions for modules who want to save region
- (NSString *)serializeCurrentRegion;
- (void)unserializeRegion:(NSString *)regionString;

#pragma mark Annotations
@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) NSArray *routes;
@property (nonatomic, readonly) id<MKAnnotation> currentAnnotation;

- (void)addAnnotation:(id <MKAnnotation>)annotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id <MKAnnotation>)annotation;
- (void)removeAnnotations:(NSArray *)annotations;
- (void)removeAllAnnotations;

- (void)addRoute:(id<MITMapRoute>) route;
- (void)removeRoute:(id<MITMapRoute>) route;

// Notification callback.
- (void)annotationTapped:(NSNotification*)notif;

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)selectAnnotation:(id<MKAnnotation>) annotation;

- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter;


- (MITMapAnnotationView *)viewForAnnotation:(id <MKAnnotation>)annotation;


@end
