#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class MGSLayer;
@class MGSLayerController;
@class MGSLayerAnnotation;
@class MGSMapView;
@protocol MGSAnnotation;

@protocol MGSLayerControllerDelegate <NSObject>
@optional
- (void)layerControllerWillRefresh:(MGSLayerController*)layerController;
- (void)layerControllerDidRefresh:(MGSLayerController*)layerController;
@end

@interface MGSLayerController : NSObject
@property (nonatomic,readonly,strong) MGSLayer *layer;
@property (nonatomic,weak) AGSLayer *nativeLayer;
@property (nonatomic,readonly) NSSet *layerAnnotations;

// The behavior for this property is a bit odd. If the graphics layer
// has a valid spatial reference, it will be returned by the spatialReference getter,
// otherwise, this property behaves like a normal R/W property
@property (nonatomic,strong) AGSSpatialReference *spatialReference;
@property (nonatomic,weak) id<MGSLayerControllerDelegate> delegate;

- (id)initWithLayer:(MGSLayer*)layer;
- (void)setNeedsRefresh;
- (void)refresh:(void(^)(void))refreshBlock;

- (MGSLayerAnnotation*)layerAnnotationForGraphic:(AGSGraphic*)graphic;
- (NSSet*)layerAnnotationsForGraphics:(NSSet*)graphics;
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
- (NSSet*)layerAnnotationsForAnnotations:(NSSet*)annotations;
@end
