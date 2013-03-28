@class MGSLayerAnnotation;
@protocol MGSAnnotation;

@interface MGSLayer ()
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
@end