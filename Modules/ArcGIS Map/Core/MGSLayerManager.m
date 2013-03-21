#import "MGSLayerManager.h"


@interface MGSLayerManager ()
- (AGSGraphicsLayer *)graphicsLayerForLayer:(MGSLayer *)layer;
- (AGSGraphic *)graphicForAnnotation:(id <MGSAnnotation>)annotation;
@end

@implementation MGSLayerManager
- (id)initWithLayer:(MGSLayer *)layer
{

}

- (AGSGraphic *)graphicForAnnotation:(id <MGSAnnotation>)annotation
{

}

- (id <MGSAnnotation>)annotationForGraphic:(AGSGraphic *)graphic
{

}


- (AGSGraphicsLayer *)delegateGraphicsLayer
{
    if ([self.delegate respondsToSelector:@selector(layerManager:graphicsLayerForLayer:)]) {
        return [self.delegate layerManager:self
                     graphicsLayerForLayer:self.layer];
    }
}

- (AGSGraphic *)delegateGraphicForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(layerManager:graphicForAnnotation:)]) {
        return [self.delegate layerManager:self
                      graphicForAnnotation:annotation];
    }
}
@end
