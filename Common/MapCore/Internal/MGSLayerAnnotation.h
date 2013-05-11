#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSSafeAnnotation.h"

@class MGSLayer;
@class AGSGraphic;

@interface MGSLayerAnnotation : NSObject <NSCopying>
@property (nonatomic,readonly,strong) AGSGraphic *graphic;
@property (nonatomic,readonly,strong) id<MGSAnnotation> annotation;

- (id)initWithLayerAnnotation:(MGSLayerAnnotation*)layerAnnotation;
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
