#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapView;
@class MGSMapLayer;

@protocol MGSAnnotation;

@protocol MGSCalloutController
- (BOOL)isPresentingCalloutForAnnotation:(MGSMapAnnotation*)annotation;
- (UIView*)viewForAnnotation:(MGSMapAnnotation*)annotation;
@end

@protocol MGSLayerDelegate <NSObject>
- (void)mapLayer:(MGSMapLayer*)layer willMoveToMapView:(MGSMapView*)mapView;
- (void)mapLayer:(MGSMapLayer*)layer didMoveToMapView:(MGSMapView*)mapView;

- (void)mapLayer:(MGSMapLayer*)layer willAddAnnotations:(NSSet*)annotations;
- (void)mapLayer:(MGSMapLayer*)layer didAddAnnotations:(NSSet*)annotations;

- (void)mapLayer:(MGSMapLayer*)layer willRemoveAnnotations:(NSSet*)annotations;
- (void)mapLayer:(MGSMapLayer*)layer didRemoveAnnotations:(NSSet*)annotations;

- (void)willReloadMapLayer:(MGSMapLayer*)mapLayer;

- (BOOL)mapLayer:(MGSMapLayer*)layer shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapLayer:(MGSMapLayer*)layer willDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;

- (UIView*)mapLayer:(MGSMapLayer*)layer calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
- (void)mapLayer:(MGSMapLayer*)layer calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;

- (void)mapLayer:(MGSMapLayer*)layer didPresentCalloutForAnnotation:(id<MGSAnnotation>)annotation;
@end

@interface MGSMapLayer : NSObject
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
