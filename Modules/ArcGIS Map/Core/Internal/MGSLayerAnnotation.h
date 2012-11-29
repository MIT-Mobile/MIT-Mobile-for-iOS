#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSAnnotation.h"

@class MGSMapLayer;

@interface MGSLayerAnnotation : NSObject <MGSAnnotation>
@property (weak) MGSMapLayer *layer;
@property (weak) AGSLayer *agsLayer;

@property (nonatomic,strong) id<NSObject> userData;
@property (strong) NSDictionary *attributes;

@property (nonatomic,readonly,strong) id<MGSAnnotation> annotation;
@property (nonatomic,readonly,strong) AGSGraphic *graphic;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
