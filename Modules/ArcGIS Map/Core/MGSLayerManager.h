#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class MGSLayer;
@class MGSLayerManager;
@class MGSLayerAnnotation;
@class MGSMapView;
@protocol MGSAnnotation;

@protocol MGSLayerManagerDelegate <NSObject>
- (AGSGraphicsLayer*)layerManager:(MGSLayerManager*)layerManager
            graphicsLayerForLayer:(MGSLayer*)layer;

- (AGSGraphic*)layerManager:(MGSLayerManager*)layerManager
       graphicForAnnotation:(id<MGSAnnotation>)annotation;
@end

@interface MGSLayerManager : NSObject
@property (nonatomic,readonly,strong) MGSLayer *layer;
@property (nonatomic,weak) MGSMapView *mapView;
@property (nonatomic,readonly,weak) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic,readonly) NSSet *allAnnotations;

// The behavior for this property is a bit odd. If the graphics layer
// has a valid spatial reference, it will be returned by the spatialReference getter,
// otherwise, this property behaves like a normal R/W property
@property (nonatomic,strong) AGSSpatialReference *spatialReference;
@property (nonatomic,weak) id<MGSLayerManagerDelegate> delegate;

- (id)initWithLayer:(MGSLayer*)layer;
- (void)syncAnnotations;

- (MGSLayerAnnotation*)layerAnnotationForGraphic:(AGSGraphic*)graphic;
- (NSSet*)layerAnnotationsForGraphics:(NSSet*)graphics;
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
- (NSSet*)layerAnnotationsForAnnotations:(NSSet*)annotations;
@end
