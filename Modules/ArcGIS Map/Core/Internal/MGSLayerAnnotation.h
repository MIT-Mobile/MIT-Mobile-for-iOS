#import <Foundation/Foundation.h>
#import "MGSAnnotation.h"

@class MGSLayer;
@class AGSGraphic;

@interface MGSLayerAnnotation : NSObject <MGSAnnotation>
@property (nonatomic,strong,readonly) id<MGSAnnotation> annotation;
@property (weak) MGSLayer *layer;

@property (nonatomic,strong) AGSGraphic *graphic;
@property (strong) NSDictionary *attributes;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
