#import "MGSMapAnnotation.h"
#import <ArcGIS/ArcGIS.h>

extern NSString* const MGSAnnotationAttributeKey;

typedef enum _MGSGraphicType {
    MGSGraphicDefault = 0,
    MGSGraphicStop
} MGSGraphicType;

@interface MGSMapAnnotation ()
@property (nonatomic,weak) AGSGraphic *agsGraphic;

+ (id)annotationWithGraphic:(AGSGraphic*)graphic;
+ (AGSSymbol*)symbolForAnnotation:(MGSMapAnnotation*)annotation defaultMarker:(MGSMarker*)templateMarker;
+ (AGSGraphic*)graphicOfType:(MGSGraphicType)graphicType
               withAnnotation:(MGSMapAnnotation*)annotation
                    template:(MGSMarker*)template;
+ (AGSGraphic*)graphicForAnnotation:(MGSMapAnnotation*)annotation template:(MGSMarker*)template;
@end