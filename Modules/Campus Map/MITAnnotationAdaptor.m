#import <QuartzCore/QuartzCore.h>

#import "MITAnnotationAdaptor.h"

@implementation MITAnnotationAdaptor
- (id)initWithMKAnnotation:(id<MKAnnotation>)annotation
{
    self = [super init];
    if (self)
    {
        self.annotation = annotation;
    }

    return self;
}

- (NSString*)title
{
    return self.annotation.title;
}

- (NSString*)detail
{
    return self.annotation.subtitle;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.annotation.coordinate;
}

- (void)setAnnotationView:(MITMapAnnotationView *)annotationView
{
    self.cachedMarker = nil;
    _annotationView = annotationView;
}

- (BOOL)isEqual:(id)object
{
    if ([super isEqual:object])
    {
        return YES;
    }

    if ([object isKindOfClass:[self class]])
    {
        return [self.annotation isEqual:[object annotation]];
    }

    return NO;
}
@end