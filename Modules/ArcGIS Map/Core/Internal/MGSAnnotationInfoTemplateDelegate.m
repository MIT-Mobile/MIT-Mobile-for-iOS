#import <CoreGraphics/CoreGraphics.h>

#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"
#import "MGSUtility.h"
#import "MGSMapView.h"
#import "MITAdditions.h"
#import "MGSCalloutView.h"

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
    
    NSString *title = [self titleForAnnotation:layerAnnotation.annotation];
    
    if ([title length])
    {
        return title;
    }
    else
    {
        return @"";
    }
}

- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSLayerAnnotation *layerAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    NSString *detail = [self detailForAnnotation:layerAnnotation.annotation];
    
    if ([detail length])
    {
        return detail;
    }
    else
    {
        return @"";
    }
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
        if (layerDelegate && [layerDelegate respondsToSelector:@selector(mapLayer:calloutViewForAnnotation:)])
        {
            resultView = [layerDelegate mapLayer:layerAnnotation.layer
                  calloutViewForAnnotation:layerAnnotation.annotation];
        }
        
        if (resultView == nil)
        {
            MGSCalloutView *calloutView = [[MGSCalloutView alloc] init];
            calloutView.autoresizesSubviews = YES;
            calloutView.imageView.image = [self imageForAnnotation:layerAnnotation.annotation];
            calloutView.titleLabel.text = [self titleForAnnotation:layerAnnotation.annotation];
            calloutView.detailLabel.text = [self detailForAnnotation:layerAnnotation.annotation];
            
            [calloutView sizeToFit];
            [calloutView setNeedsLayout];
            
            resultView = calloutView;
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
    
    return nil;
}


- (NSString*)detailForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation respondsToSelector:@selector(detail)])
    {
        return [annotation detail];
    }
    
    return nil;
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
