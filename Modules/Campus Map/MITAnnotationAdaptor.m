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
        MGSMarkerOptions options = self.markerOptions;
        
        BOOL frameIsValid = !((CGAffineTransformEqualToTransform(legacyAnnotationView.transform, CGAffineTransformIdentity) == NO) ||
                               CGRectIsNull(legacyAnnotationView.frame) ||
                               CGRectIsInfinite(legacyAnnotationView.frame) ||
                               CGRectIsEmpty(legacyAnnotationView.frame));
        CGRect frame;
        CGRect bounds = legacyAnnotationView.bounds;
        if (frameIsValid) {
            frame = legacyAnnotationView.frame;
            
            CGRect stdFrame = CGRectStandardize(frame);
            stdFrame = CGRectOffset(stdFrame, (CGRectGetWidth(stdFrame) / 2.0), (CGRectGetHeight(stdFrame) / 2.0));
            
            options.offset = CGPointMake(stdFrame.origin.x,-stdFrame.origin.y);
            self.markerOptions = options;
            
            legacyAnnotationView.frame = bounds;
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0.0);
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