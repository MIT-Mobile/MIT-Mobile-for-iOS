#import <ArcGIS/ArcGIS.h>

@protocol MGSAnnotation;

@interface MGSAnnotationSymbol : AGSPictureMarkerSymbol
@property (nonatomic, readonly, strong) id<MGSAnnotation> annotation;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation;
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation defaultImageName:(NSString *)imageName;

@end
