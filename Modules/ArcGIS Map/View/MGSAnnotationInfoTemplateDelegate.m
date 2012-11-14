#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSMapLayer.h"
#import "MGSMapAnnotation.h"
#import "MGSMapAnnotation+Protected.h"
#import "MGSMapAnnotation+AGS.h"

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
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.title;
}

- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.detail;
}

-(UIImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.image;
}

- (UIView*)customViewForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    
    UIView *resultView = nil;
    
    if (annotation.layer)
    {
        UIViewController<MGSCalloutController> *vc = annotation.layer.calloutController;
        resultView = [vc viewForAnnotation:annotation];
    }
    
    if (resultView == nil)
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
    
    return resultView;
}

@end
