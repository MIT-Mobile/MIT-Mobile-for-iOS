#import <ArcGIS/ArcGIS.h>

@protocol MGSAnnotation;

@interface MGSAnnotationSymbol : AGSSymbol
@property (nonatomic,strong) id<MGSAnnotation> annotation;
+ (CGPoint)toScreenPointWithX:(double)x
                            y:(double)y
                     envelope:(AGSEnvelope *)env
                   resolution:(double)res;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation;
- (UIImage *)swatchForGeometryType:(AGSGeometryType)geometryType size:(CGSize)size;
@end
