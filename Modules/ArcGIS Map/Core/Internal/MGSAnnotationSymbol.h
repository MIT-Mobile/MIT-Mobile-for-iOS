#import <ArcGIS/ArcGIS.h>

@class MGSLayerAnnotation;

@interface MGSAnnotationSymbol : AGSSymbol
@property (nonatomic,strong) MGSLayerAnnotation* annotation;

+ (CGPoint)toScreenPointWithX:(double)x
                            y:(double)y
                     envelope:(AGSEnvelope *)env
                   resolution:(double)res;

- (id)initWithAnnotation:(MGSLayerAnnotation*)annotation;
- (UIImage *)swatchForGeometryType:(AGSGeometryType)geometryType size:(CGSize)size;
@end
