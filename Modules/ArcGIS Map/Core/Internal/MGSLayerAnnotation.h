#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSAnnotation.h"

@class MGSLayer;

@interface MGSLayerAnnotation : NSObject <MGSAnnotation>
@property (nonatomic,strong,readonly) id<MGSAnnotation> annotation;
@property (weak) MGSLayer *layer;
@property (weak) AGSLayer *agsLayer;

@property (nonatomic,strong) AGSGraphic *graphic;
@property (strong) NSDictionary *attributes;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
