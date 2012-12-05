#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSCalloutController
- (BOOL)isPresentingCalloutForAnnotation:(MGSMapAnnotation*)annotation;
- (UIView*)viewForAnnotation:(MGSMapAnnotation*)annotation;
@end

@protocol MGSLayerDelegate <NSObject>
- (void)mapLayer:(MGSLayer*)layer willMoveToMapView:(MGSMapView*)mapView;
- (void)mapLayer:(MGSLayer*)layer didMoveToMapView:(MGSMapView*)mapView;

- (void)mapLayer:(MGSLayer*)layer willAddAnnotations:(NSSet*)annotations;
- (void)mapLayer:(MGSLayer*)layer didAddAnnotations:(NSSet*)annotations;

- (void)mapLayer:(MGSLayer*)layer willRemoveAnnotations:(NSSet*)annotations;
- (void)mapLayer:(MGSLayer*)layer didRemoveAnnotations:(NSSet*)annotations;

- (void)willReloadMapLayer:(MGSLayer*)mapLayer;

- (BOOL)mapLayer:(MGSLayer*)layer shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapLayer:(MGSLayer*)layer willDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;

- (UIView*)mapLayer:(MGSLayer*)layer calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapLayer:(MGSLayer*)layer calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;

- (void)mapLayer:(MGSLayer*)layer didPresentCalloutForAnnotation:(id<MGSAnnotation>)annotation;
@end

@interface MGSLayer : NSObject
@property (weak) id<MGSLayerDelegate> delegate;
@property (strong) NSString *name;
@property (weak,readonly) MGSMapView *mapView;
@property (strong) UIViewController<MGSCalloutController> *calloutController;

@property (strong) NSArray *annotations;
@property (strong) MGSMarker *markerTemplate;
@property (assign,nonatomic) BOOL hidden;

- (void)addAnnotation:(id<MGSAnnotation>)annotation;
- (void)addAnnotations:(NSSet *)objects;
- (void)deleteAnnotation:(id<MGSAnnotation>)annotation;
- (void)deleteAnnotations:(NSSet*)annotation;
- (void)deleteAllAnnotations;

- (MKCoordinateRegion)regionForAnnotations:(NSSet*)annotations;

- (id)initWithName:(NSString*)name;
- (void)refreshLayer;
@end
