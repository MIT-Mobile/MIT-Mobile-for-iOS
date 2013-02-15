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
    
    if ([super isEqual:object])
    {
        result = YES;
    }
    else if ([object isKindOfClass:[MGSLayerAnnotation class]])
    {
        result = [self isEqualToLayerAnnotation:(MGSLayerAnnotation*)object];
    }
    
    return result;
}

- (BOOL)isEqualToLayerAnnotation:(MGSLayerAnnotation*)annotation
{
    return ([self.annotation isEqual:annotation.annotation] &&
            [self.graphic isEqual:annotation.graphic]);
}

#pragma mark - AGSAnnotation wrapper delegate
- (BOOL)canShowCallout
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation canShowCallout];
    }
    
    return NO;
}

- (NSString*)title
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation title];
    }
    
    return nil;
}

- (NSString*)detail
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation detail];
    }
    
    return nil;
}

- (UIImage*)calloutImage
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation calloutImage];
    }
    
    return nil;
}

- (UIImage*)markerImage
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation markerImage];
    }
    
    return [UIImage imageNamed:@"map/map_pin_complete"];
}

- (UIView*)calloutView
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation calloutView];
    }
    
    return nil;
}

- (MGSAnnotationType)annotationType
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation annotationType];
    }
    
    return MGSAnnotationMarker;
}

- (id<NSObject>)userData
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation userData];
    }
    
    return nil;
}

- (CLLocationCoordinate2D)coordinate
{
    if ([self.annotation respondsToSelector:_cmd])
    {
        return [self.annotation coordinate];
    }
    
    return CLLocationCoordinate2DMake(0,0);
}

- (NSArray*)points {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation points];
    }
    
    return nil;
}

- (UIColor*)strokeColor {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation strokeColor];
    }
    
    return nil;
}

- (UIColor*)fillColor {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation fillColor];
    }
    
    return nil;
}

- (CGFloat)lineWidth {
    if ([self.annotation respondsToSelector:_cmd]) {
        return [self.annotation lineWidth];
    }
    
    return 0.0;
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
