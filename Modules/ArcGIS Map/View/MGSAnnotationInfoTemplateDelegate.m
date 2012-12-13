#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"
#import "MGSUtility.h"

@implementation MGSAnnotationInfoTemplateDelegate
+ (id)sharedInfoTemplate
{
    static MGSAnnotationInfoTemplateDelegate *sharedDelegate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedDelegate == nil)
        {
            sharedDelegate = [self annotationInfoTemplate];
        }
    });
    
    return sharedDelegate;
}

+ (id)annotationInfoTemplate
{
    return [[self alloc] init];
}

- (NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSLayerAnnotation *layerAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    return [self titleForAnnotation:layerAnnotation.annotation];
}

- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSLayerAnnotation *layerAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    return [self detailForAnnotation:layerAnnotation.annotation];
}

-(UIImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSLayerAnnotation *layerAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    return [self imageForAnnotation:layerAnnotation.annotation];
}

- (UIView*)customViewForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSLayerAnnotation *layerAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    UIView *resultView = nil;
    
    if (layerAnnotation.layer)
    {
        id<MGSLayerDelegate> layerDelegate = layerAnnotation.layer.delegate;
        UIView *view = nil;
        if (layerDelegate && [layerDelegate respondsToSelector:@selector(mapLayer:calloutViewForAnnotation:)])
        {
            view = [layerDelegate mapLayer:layerAnnotation.layer
                  calloutViewForAnnotation:layerAnnotation.annotation];
        }
        
        if (view == nil)
        {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor clearColor];
            
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
            titleLabel.text = [self titleForGraphic:graphic
                                        screenPoint:screen
                                           mapPoint:mapPoint];
            
            UILabel *detailLabel = [[UILabel alloc] init];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
            titleLabel.numberOfLines = 0;
            titleLabel.text = [self detailForGraphic:graphic
                                         screenPoint:screen
                                            mapPoint:mapPoint];
            
            UIImage *image = [self imageForGraphic:graphic
                                       screenPoint:screen
                                          mapPoint:mapPoint];
            if (image)
            {
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.image = image;
            }
            
            resultView = view;
        }
    }
    
    return resultView;
}

- (NSString*)titleForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation respondsToSelector:@selector(title)])
    {
        return [annotation title];
    }
    
    return @"";
}


- (NSString*)detailForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation respondsToSelector:@selector(detail)])
    {
        return [annotation detail];
    }
    
    return @"";
}


- (UIImage*)imageForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation respondsToSelector:@selector(image)])
    {
        return [annotation image];
    }

    return nil;
}
@end
