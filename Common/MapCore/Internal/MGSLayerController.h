#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class MGSLayer;
@class MGSLayerController;
@class MGSLayerAnnotation;
@class MGSMapView;
@protocol MGSAnnotation;

@protocol MGSLayerControllerDelegate <NSObject>
@optional
- (AGSGraphicsLayer*)layerManager:(MGSLayerController*)layerManager
            graphicsLayerForLayer:(MGSLayer*)layer;

- (AGSGraphic*)layerManager:(MGSLayerController*)layerManager
       graphicForAnnotation:(id<MGSAnnotation>)annotation;

- (void)layerManagerWillSynchronizeAnnotations:(MGSLayerController*)layerManager;
- (void)layerManagerDidSynchronizeAnnotations:(MGSLayerController*)layerManager;
@end

@interface MGSLayerController : NSObject
@property (nonatomic,readonly,strong) MGSLayer *layer;
@property (nonatomic,readonly,strong) AGSLayer *nativeLayer;
@property (nonatomic,readonly) NSSet *layerAnnotations;

// The behavior for this property is a bit odd. If the graphics layer
// has a valid spatial reference, it will be returned by the spatialReference getter,
// otherwise, this property behaves like a normal R/W property
@property (nonatomic,strong) AGSSpatialReference *spatialReference;
@property (nonatomic,weak) id<MGSLayerControllerDelegate> delegate;

- (id)initWithLayer:(MGSLayer*)layer;
- (void)refresh;

- (MGSLayerAnnotation*)layerAnnotationForGraphic:(AGSGraphic*)graphic;
- (NSSet*)layerAnnotationsForGraphics:(NSSet*)graphics;
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
- (NSSet*)layerAnnotationsForAnnotations:(NSSet*)annotations;
@end
