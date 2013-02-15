#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSSafeAnnotation.h"

@class MGSLayer;
@class AGSGraphic;

@interface MGSLayerAnnotation : MGSSafeAnnotation <AGSInfoTemplateDelegate>
@property (weak) MGSLayer *layer;

@property (nonatomic,strong) AGSGraphic *graphic;
@property (strong) NSDictionary *attributes;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
