#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface MGSAnnotationInfoTemplateDelegate : NSObject  <AGSInfoTemplateDelegate>
+ (id)sharedInfoTemplate;
+ (id)annotationInfoTemplate;

- (NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
- (UIImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
- (UIView*)customViewForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint;
@end
