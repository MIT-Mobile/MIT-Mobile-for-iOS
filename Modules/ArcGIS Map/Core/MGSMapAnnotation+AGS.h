#import <ArcGIS/ArcGIS.h>
#import "MGSMapAnnotation.h"

@protocol MGSAnnotation;

extern NSString* const MGSAnnotationAttributeKey;

typedef enum _MGSGraphicType {
    MGSGraphicDefault = 0,
    MGSGraphicStop
} MGSGraphicType;