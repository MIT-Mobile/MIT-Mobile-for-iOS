#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class MGSLayer;
@class MGSLayerManager;
@protocol MGSAnnotation;

@protocol MGSLayerManagerDelegate <NSObject>
- (AGSGraphicsLayer*)layerManager:(MGSLayerManager*)layerManager graphicsLayerForLayer:(MGSLayer*)layer;
- (AGSGraphic*)layerManager:(MGSLayerManager*)layerManager graphicForAnnotation:(id<MGSAnnotation>)annotation;
@end

@interface MGSLayerManager : NSObject
/**
 *  The current layer being managed.
 *
 */
@property (nonatomic,readonly,strong) MGSLayer *layer;

/**
 *  The backing ArcGIS graphics layer.
 *
 *  The graphics layer will be created on access. If a delegate
 *  has been set and it responds to the layerManager:graphicsLayerForLayer:
 *  selector, this property will be set to the value returned
 *  by the method.
 *
 *  @warning This property may be nil. If it is, the MGSLayer will not be
 *  added to the map
 *
 */
@property (nonatomic,readonly,strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic,strong) NSArray *graphics;
@property (nonatomic,strong) AGSSpatialReference *defaultSpatialReference;
@property (nonatomic,weak) id<MGSLayerManagerDelegate> delegate;

- (id)initWithLayer:(MGSLayer*)layer;
- (AGSGraphic*)graphicForAnnotation:(id<MGSAnnotation>)annotation;
- (id<MGSAnnotation>)annotationForGraphic:(AGSGraphic*)graphic;
@end
