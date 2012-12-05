#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSAnnotation.h"

@class MGSLayer;

@interface MGSLayerAnnotation : NSObject
@property (weak) MGSLayer *layer;
@property (weak) AGSLayer *agsLayer;

@property (nonatomic,strong) id<NSObject> userData;
@property (strong) NSDictionary *attributes;

@property (nonatomic,strong) id<MGSAnnotation> annotation;
@property (nonatomic,strong) AGSGraphic *graphic;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
