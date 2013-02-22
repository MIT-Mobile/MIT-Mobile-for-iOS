#import "MGSLayerAnnotation.h"
#import "MGSAnnotation.h"

@interface MGSLayerAnnotation (AGSInfoTemplateDelegate)
- (NSString*)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
- (NSString*)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
- (AGSImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
@end

@implementation MGSLayerAnnotation
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic
{
    self = [super initWithAnnotation:annotation];
    
    if (self)
    {
        self.graphic = graphic;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    BOOL result = NO;
    
    if ([super isEqual:object]) {
        result = YES;
    } else if ([object isKindOfClass:[MGSLayerAnnotation class]]) {
        result = [self isEqualToLayerAnnotation:(MGSLayerAnnotation*)object];
    }
    
    return result;
}

- (BOOL)isEqualToLayerAnnotation:(MGSLayerAnnotation*)annotation
{
    return ([self.annotation isEqual:annotation.annotation] &&
            [self.graphic isEqual:annotation.graphic]);
}
@end

@implementation MGSLayerAnnotation (AGSInfoTemplateDelegate)
- (NSString*)titleForGraphic:(AGSGraphic *)graphic
                 screenPoint:(CGPoint)screen
                    mapPoint:(AGSPoint *)mapPoint {
    if ([self.graphic isEqual:graphic]) {
        return self.title;
    }
    
    return nil;
}

- (NSString*)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint {
    if ([self.graphic isEqual:graphic]) {
        return self.detail;
    }
    
    return nil;
}

- (AGSImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint {
    if ([self.graphic isEqual:graphic]) {
        return self.calloutImage;
    }

    return nil;
}
@end
