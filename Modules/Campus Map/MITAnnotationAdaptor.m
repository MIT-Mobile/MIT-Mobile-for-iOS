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
        MGSMarkerOptions options = self.markerOptions;
        
        CGRect annotationFrame = CGRectZero;
        BOOL frameIsInvalid = ((CGAffineTransformEqualToTransform(legacyAnnotationView.transform, CGAffineTransformIdentity) == NO) ||
                               CGRectIsNull(legacyAnnotationView.frame) ||
                               CGRectIsInfinite(legacyAnnotationView.frame) ||
                               CGRectIsEmpty(legacyAnnotationView.frame));
        if (frameIsInvalid) {
            DDLogWarn(@"handed an invalid frame rect, attempting to recover");
            annotationFrame = legacyAnnotationView.bounds;
        } else {
            annotationFrame = legacyAnnotationView.frame;
        }
        
        // MKAnnotationView automatically centers its frame if an image
        // is added so undo the centering then use the remainder for the offset
        CGFloat xOffset = annotationFrame.origin.y + (annotationFrame.size.height / 2.0);
        CGFloat yOffset = annotationFrame.origin.x + (annotationFrame.size.width / 2.0);
        options.offset = CGPointMake((CGFloat) round(xOffset), (CGFloat) round(yOffset));
        self.markerOptions = options;
        
        if (frameIsInvalid == NO) {
            DDLogError(@"attempting to render view with an invalid frame");
        }
        
        UIGraphicsBeginImageContextWithOptions(legacyAnnotationView.bounds.size, NO, 0.0);
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