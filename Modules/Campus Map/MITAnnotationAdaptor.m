#import <QuartzCore/QuartzCore.h>

#import "MITAnnotationAdaptor.h"
#import "MGSMarker.h"


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

- (MGSMarker*)marker
{
    if (self.cachedMarker == nil)
    {
        MGSMarker *marker = [[MGSMarker alloc] init];
        marker.style = MGSMarkerStyleImage;

        // If scale is 0, it'll follows the screen scale for creating the bounds
        UIGraphicsBeginImageContextWithOptions(self.annotationView.frame.size, NO, 0);

        // - [CALayer renderInContext:] also renders subviews
        [self.annotationView.layer renderInContext:UIGraphicsGetCurrentContext()];

        // Get the image out of the context
        marker.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return self.cachedMarker;
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