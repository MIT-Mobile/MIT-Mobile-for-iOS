#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#import "MITMapView.h"
#import "MITAnnotationAdaptor.h"

@implementation MITAnnotationAdaptor
- (id)initWithMKAnnotation:(id<MKAnnotation>)annotation
{
    self = [super init];
    if (self)
    {
        self.mkAnnotation = annotation;
    }
    
    return self;
}

- (NSString*)title
{
    return self.mkAnnotation.title;
}

- (NSString*)detail
{
    return self.mkAnnotation.subtitle;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.mkAnnotation.coordinate;
}

- (UIImage*)markerImage
{
    UIImage *image = nil;
    MITMapAnnotationView *legacyAnnotationView = nil;
    
    if (self.calloutAnnotationView) {
        legacyAnnotationView = self.calloutAnnotationView;
    } else if ([self.mapView.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        legacyAnnotationView = [self.mapView.delegate mapView:self.mapView
                                            viewForAnnotation:self.mkAnnotation];
    }
    
    if (legacyAnnotationView && ([legacyAnnotationView isKindOfClass:[MITPinAnnotationView class]] == NO))
    {
        [legacyAnnotationView sizeToFit];
        CGRect annotationBounds = legacyAnnotationView.bounds;
        MGSMarkerOptions options = self.markerOptions;
        
        // MKAnnotationView automatically centers its frame if an image
        // is added so undo the centering then use the remainder for the offset
        CGRect frame = legacyAnnotationView.frame;
        CGFloat xOffset = frame.origin.y + (frame.size.height / 2.0);
        CGFloat yOffset = frame.origin.x + (frame.size.width / 2.0);
        options.offset = CGPointMake((CGFloat) round(xOffset), (CGFloat) round(yOffset));
        self.markerOptions = options;
        
        legacyAnnotationView.frame = annotationBounds;
        
        UIGraphicsBeginImageContextWithOptions(annotationBounds.size, NO, 0.0);
        legacyAnnotationView.layer.backgroundColor = [[UIColor clearColor] CGColor];
        [legacyAnnotationView.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (BOOL)isEqual:(id)object
{
    if ([super isEqual:object])
    {
        return YES;
    }
    
    if ([object isKindOfClass:[self class]])
    {
        MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)object;
        return [self.mkAnnotation isEqual:adaptor.mkAnnotation];
    }
    
    return NO;
}
@end