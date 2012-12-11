#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSLayerDelegate <NSObject>
@optional
- (void)mapLayer:(MGSLayer*)layer willMoveToMapView:(MGSMapView*)mapView;
- (void)mapLayer:(MGSLayer*)layer didMoveToMapView:(MGSMapView*)mapView;

- (void)mapLayer:(MGSLayer*)layer willAddAnnotations:(NSArray*)annotations;
- (void)mapLayer:(MGSLayer*)layer didAddAnnotations:(NSArray*)annotations;

- (void)mapLayer:(MGSLayer*)layer willRemoveAnnotations:(NSArray*)annotations;
- (void)mapLayer:(MGSLayer*)layer didRemoveAnnotations:(NSArray*)annotations;

- (void)willReloadMapLayer:(MGSLayer*)mapLayer;

- (BOOL)mapLayer:(MGSLayer*)layer shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (UIView*)mapLayer:(MGSLayer*)layer calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
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
- (void)addAnnotations:(NSArray *)objects;
- (void)deleteAnnotation:(id<MGSAnnotation>)annotation;
- (void)deleteAnnotations:(NSArray*)annotation;
- (void)deleteAllAnnotations;

- (MKCoordinateRegion)regionForAnnotations:(NSSet*)annotations;

- (id)initWithName:(NSString*)name;
- (void)refreshLayer;

- (BOOL)shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
@end
