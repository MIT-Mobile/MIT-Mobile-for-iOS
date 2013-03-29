#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class MGSLayer;
@class MGSLayerManager;
@class MGSLayerAnnotation;
@protocol MGSAnnotation;

@protocol MGSLayerManagerDelegate <NSObject>
- (AGSGraphicsLayer*)layerManager:(MGSLayerManager*)layerManager
            graphicsLayerForLayer:(MGSLayer*)layer
             withSpatialReference:(AGSSpatialReference*)spatialReference;

- (AGSGraphic*)layerManager:(MGSLayerManager*)layerManager
       graphicForAnnotation:(id<MGSAnnotation>)annotation;
@end

@interface MGSLayerManager : NSObject
@property (nonatomic,readonly,strong) MGSLayer *layer;
@property (nonatomic,readonly) NSSet *allAnnotations;
@property (nonatomic,readonly,strong) AGSGraphicsLayer *graphicsLayer;

// The behavior for this property is a bit odd. If the graphics layer
// has a valid spatial reference, it will be returned by the spatialReference getter,
// otherwise, this property behaves like a normal R/W property
@property (nonatomic,strong) AGSSpatialReference *spatialReference;
@property (nonatomic,weak) id<MGSLayerManagerDelegate> delegate;

- (id)initWithLayer:(MGSLayer*)layer;
- (void)syncAnnotations;
- (BOOL)loadGraphicsLayerWithSpatialReference:(AGSSpatialReference*)spatialReference;

- (MGSLayerAnnotation*)layerAnnotationForGraphic:(AGSGraphic*)graphic;
- (NSSet*)layerAnnotationsForGraphics:(NSSet*)graphics;
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
- (NSSet*)layerAnnotationsForAnnotations:(NSSet*)annotations;
@end
