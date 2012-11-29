#import "MGSLayerAnnotation.h"

#import <ArcGIS/ArcGIS.h>
#import "MGSAnnotation.h"

@interface MGSLayerAnnotation ()
@property (nonatomic,strong) id<MGSAnnotation> annotation;
@property (nonatomic,strong) AGSGraphic *graphic;
@end


@implementation MGSLayerAnnotation
- (id)init
{
    self = nil;
    return nil;
}

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic
{
    self = [super init];
    
    if (self)
    {
        self.annotation = annotation;
        self.graphic = graphic;
    }
    
    return self;
}


#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)(val)) << (howmuch)) | (((NSUInteger)(val)) >> (NSUINT_BIT - (howmuch))))
- (NSUInteger)hash
{
    return (NSUINTROTATE([self.annotation hash], NSUINT_BIT >> 1) ^
            [self.graphic hash]);
}

- (BOOL)isEqual:(id)object
{
    BOOL result = NO;
    
    if ([super isEqual:object])
    {
        result = YES;
    }
    else if ([object conformsToProtocol:@protocol(MGSAnnotation)])
    {
        result = [self.annotation isEqual:object];
    }
    else if ([object isKindOfClass:[AGSGraphic class]])
    {
        result = [self.graphic isEqual:object];
    }
    else if ([object isKindOfClass:[MGSLayerAnnotation class]])
    {
        result = [self isEqualToLayerAnnotation:(MGSLayerAnnotation*)object];
    }
    
    return result;
}

- (BOOL)isEqualToLayerAnnotation:(MGSLayerAnnotation*)annotation
{
    return ([self.annotation isEqual:annotation.annotation] &&
            [self.graphic isEqual:annotation.graphic]);
}
@end
