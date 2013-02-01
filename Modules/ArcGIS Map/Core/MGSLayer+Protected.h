#import "MGSLayer.h"
#import <ArcGIS/ArcGIS.h>

@class MGSMapView;
@class MGSLayerAnnotation;
@protocol MGSAnnotation;

@interface MGSLayer ()
@property (nonatomic,weak) MGSMapView *mapView;
@property (nonatomic,strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic,strong) AGSRenderer *renderer;
@property (nonatomic,readonly) BOOL hasGraphicsLayer;

// This method is similar to -[UIViewController loadView]
// It should create a new instance of AGSGraphicsLayer
// (or a subclass) and assign it to the 'graphicsLayer'
// property before returning
- (void)loadGraphicsLayer;

// Called wherever a new graphic is needed for an annotation.
// This should allow subclasses to tweak how the AGSGraphic objects
// are created without having to poke at the internals of MGSLayer.
// The default implementation
- (AGSGraphic*)loadGraphicForAnnotation:(id<MGSAnnotation>)annotation;

- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
@end