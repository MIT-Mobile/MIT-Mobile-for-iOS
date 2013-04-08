#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MGSMapView;
@class MGSLayer;

@protocol MGSAnnotation;

@protocol MGSLayerDelegate <NSObject>
@optional
- (void)mapLayer:(MGSLayer*)layer willAddAnnotations:(NSOrderedSet*)annotations;
- (void)mapLayer:(MGSLayer*)layer didAddAnnotations:(NSOrderedSet*)annotations;

- (void)mapLayer:(MGSLayer*)layer willRemoveAnnotations:(NSOrderedSet*)annotations;
- (void)mapLayer:(MGSLayer*)layer didRemoveAnnotations:(NSOrderedSet*)annotations;
@end

@interface MGSLayer : NSObject
@property (nonatomic,weak) id<MGSLayerDelegate> delegate;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSOrderedSet *annotations;

- (id)init;
- (id)initWithName:(NSString*)name;

- (void)addAnnotations:(NSOrderedSet*)annotations;
- (void)addAnnotation:(id<MGSAnnotation>)annotation;
- (void)addAnnotationsFromArray:(NSArray*)annotations;

- (void)deleteAnnotations:(NSOrderedSet *)annotations;
- (void)deleteAnnotation:(id <MGSAnnotation>)annotation;
- (void)deleteAnnotationsFromArray:(NSArray *)annotations;
- (void)deleteAnnotationsFromSet:(NSSet*)annotations;

- (void)deleteAllAnnotations;

- (MKCoordinateRegion)regionForAnnotations;
@end

@interface MGSLayer (Subclassing)

// Important: The add/remove methods below may be called
// multiple times! Since a layer may be safely added to
// several map view, it will receive notifications for
// each map view it is added/removed from
- (void)willAddLayerToMapView:(MGSMapView*)mapView;
- (void)didAddLayerToMapView:(MGSMapView*)mapView;
- (void)willRemoveLayerFromMapView:(MGSMapView*)mapView;
- (void)didRemoveLayerFromMapView:(MGSMapView*)mapView;

- (void)willAddAnnotations:(NSOrderedSet*)annotations;
- (void)didAddAnnotations:(NSOrderedSet*)annotations;
- (void)willRemoveAnnotations:(NSOrderedSet*)annotations;
- (void)didRemoveAnnotations:(NSOrderedSet*)annotations;
@end