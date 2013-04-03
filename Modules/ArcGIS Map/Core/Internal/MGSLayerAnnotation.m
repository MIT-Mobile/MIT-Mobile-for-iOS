#import "MGSLayerAnnotation.h"
#import "MGSAnnotation.h"
#import "MGSLayer.h"


@interface MGSLayerAnnotation ()
@property (nonatomic,strong) AGSGraphic *graphic;
@property (nonatomic,strong) id<MGSAnnotation> annotation;
@end

@implementation MGSLayerAnnotation

- (id)initWithLayerAnnotation:(MGSLayerAnnotation*)layerAnnotation
{
    self = [super init];

    if (self) {
        self.graphic = layerAnnotation.graphic;
        self.annotation = layerAnnotation.annotation;
    }

    return self;
}

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic
{
    self = [super init];
    
    if (self)
    {
        self.graphic = graphic;
        self.annotation = annotation;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([super isEqual:object]) {
        return YES;
    } else if ([object isKindOfClass:[MGSLayerAnnotation class]]) {
        return [self isEqualToLayerAnnotation:(MGSLayerAnnotation*)object];
    }

    return NO;
}

- (BOOL)isEqualToLayerAnnotation:(MGSLayerAnnotation*)annotation
{
    return ([self.annotation isEqual:annotation.annotation] &&
            [self.graphic isEqual:annotation.graphic]);
}

- (id)copyWithZone:(NSZone*)zone
{
    return [[[self class] allocWithZone:zone] initWithAnnotation:self.annotation
                                                         graphic:self.graphic];
}
@end
