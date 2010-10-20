
#import <UIKit/UIKit.h>

#import "MapTileCache.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MITMapAnnotationView.h"
#import "MITMapAnnotationCalloutView.h"
#import "MITMapScrollView.h"
#import "MITProjection.h"
#import "PostData.h"
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

@end

@interface MITMapView : UIView <UIScrollViewDelegate, CLLocationManagerDelegate, PostDataDelegate >{

	NSArray* _mapLevels;
	
	UIView* _mapContentView;
	
	MITMapScrollView* _scrollView;
	
	CATiledLayer* _tiledLayer;
	
	UIImageView* _locationView;
		
	BOOL _showsUserLocation;
	
	BOOL _stayCenteredOnUserLocation;
	
	CLLocationManager* _locationManager;
	
	MITMapUserLocation* _userLocationAnnotation;
	
	id<MITMapViewDelegate> _mapDelegate;
	
	NSMutableArray* _annotations;
	
	NSMutableArray* _annotationViews;
	
	NSMutableArray* _routes;
		
	// dictionary of uiimageviews used for preloading some map data. These views 
	// should be removed as the data actually loads. 
	NSMutableDictionary* _preloadedLayers;
	
	MITMapAnnotationCalloutView *_currentCallout;
	
	RouteView* _routeView;
	
	// NorthWest and SouthEast corners of the map
	CLLocationCoordinate2D _nw;
	CLLocationCoordinate2D _se;

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


// get the unscaled screen coordinate for a location
-(CGPoint) unscaledScreenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

-(CGPoint) screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

// get the geographic coordinate for a point on our map
-(CLLocationCoordinate2D) coordinateForScreenPoint:(CGPoint) point;


-(void) setCenterCoordinate:(CLLocationCoordinate2D) coordinate animated:(BOOL)animated;

-(void) hideCallout;

-(void) refreshCallout;

-(void) positionAnnotationView:(MITMapAnnotationView *)annotationView;

#pragma mark Annotations
@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) NSArray *routes;

- (void)addAnnotation:(id <MKAnnotation>)annotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id <MKAnnotation>)annotation;
- (void)removeAnnotations:(NSArray *)annotations;

- (void)addRoute:(id<MITMapRoute>) route;
- (void)removeRoute:(id<MITMapRoute>) route;

// Notification callback.
- (void)annotationTapped:(NSNotification*)notif;

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)selectAnnotation:(id<MKAnnotation>) annotation;

- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter;


- (MITMapAnnotationView *)viewForAnnotation:(id <MKAnnotation>)annotation;

@end
