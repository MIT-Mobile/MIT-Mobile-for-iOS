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
            UITableViewCell *view = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                           reuseIdentifier:nil];
            view.backgroundColor = [UIColor clearColor];
            
            view.textLabel.backgroundColor = [UIColor clearColor];
            view.textLabel.textColor = [UIColor whiteColor];
            view.textLabel.text = [self titleForGraphic:graphic
                                            screenPoint:screen
                                               mapPoint:mapPoint];
            
            view.detailTextLabel.backgroundColor = [UIColor clearColor];
            view.detailTextLabel.textColor = [UIColor whiteColor];
            view.detailTextLabel.numberOfLines = 0;
            view.detailTextLabel.text = [self detailForGraphic:graphic
                                                   screenPoint:screen
                                                      mapPoint:mapPoint];
            
            view.imageView.image = [self imageForGraphic:graphic
                                             screenPoint:screen
                                                mapPoint:mapPoint];
            
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
    if ([annotation respondsToSelector:@selector(image)])
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
