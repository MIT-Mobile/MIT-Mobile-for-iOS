#import "MGSLayer+AGS.h"

@class MGSLayerAnnotation;
@protocol MGSAnnotation;

@interface MGSLayer ()
@property (nonatomic,readonly) NSArray *internalAnnotations;
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
@end