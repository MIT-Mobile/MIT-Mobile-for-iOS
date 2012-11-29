#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MGSMapAnnotation+AGS.h"

@class MGSMarker;
@class AGSGraphic;
@protocol MGSAnnotation;


@interface MGSIMapAnnotation : NSObject
+ (id)annotationWithGraphic:(AGSGraphic*)graphic;
+ (AGSSymbol*)symbolForAnnotation:(id<MGSAnnotation>)annotation defaultMarker:(MGSMarker*)templateMarker;
+ (AGSGraphic*)graphicOfType:(MGSGraphicType)graphicType
              withAnnotation:(id<MGSAnnotation>)annotation
                    template:(MGSMarker*)template;
+ (AGSGraphic*)graphicForAnnotation:(id<MGSAnnotation>)annotation template:(MGSMarker*)template;
@end
