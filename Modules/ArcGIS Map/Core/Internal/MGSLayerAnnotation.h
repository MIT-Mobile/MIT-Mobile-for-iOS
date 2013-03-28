#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSSafeAnnotation.h"

@class MGSLayer;
@class AGSGraphic;

@interface MGSLayerAnnotation : NSObject <AGSInfoTemplateDelegate,NSCopying>
@property (nonatomic,readonly,strong) AGSGraphic *graphic;
@property (nonatomic,readonly,strong) id<MGSAnnotation> annotation;
@property (nonatomic,readonly) MGSSafeAnnotation* wrappedAnnotation;

- (id)initWithLayerAnnotation:(MGSLayerAnnotation*)layerAnnotation;
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
