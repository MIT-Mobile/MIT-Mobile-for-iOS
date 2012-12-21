#import "MGSAnnotationSymbol.h"
#include "MGSLayerAnnotation.h"

@implementation MGSAnnotationSymbol
- (id)initWithLayerAnnotation:(MGSLayerAnnotation*)annotation
{
    self = [super init];
    
    if (self)
    {
        self.annotation = annotation;
    }
    
    return self;
}

- (void)drawGraphic:(AGSGraphic *) graphic
          inContext:(CGContextRef) context
        forEnvelope:(AGSEnvelope *) env
       atResolution:(double) resolution
{
    CGRect gfxFrame = CGRectZero;
    
    gfxFrame.origin = [MGSAnnotationSymbol toScreenPointWithX:graphic.geometry.envelope.xmin
                                                            y:graphic.geometry.envelope.ymin
                                                     envelope:env
                                                   resolution:resolution];
    
    CGPoint origin = [MGSAnnotationSymbol toScreenPointWithX:graphic.geometry.envelope.xmin
                                                           y:graphic.geometry.envelope.ymin
                                                    envelope:env
                                                  resolution:resolution];
    
    CGPoint max = [MGSAnnotationSymbol toScreenPointWithX:graphic.geometry.envelope.xmax
                                                        y:graphic.geometry.envelope.ymax
                                                 envelope:env
                                               resolution:resolution];
    
    gfxFrame.size.width = max.x - origin.x;
    gfxFrame.size.height = max.y - origin.y;
    gfxFrame = CGRectStandardize(gfxFrame);
    
    
    AGSEnvelope *graphicEnv = graphic.geometry.envelope;
    CGRect gfxRect = CGRectMake(graphicEnv.xmin,graphicEnv.ymin,graphicEnv.width,graphicEnv.height);
    
}

@end
