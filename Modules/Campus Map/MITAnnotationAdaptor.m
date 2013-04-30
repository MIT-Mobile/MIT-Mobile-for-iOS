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
    MITMapAnnotationView *legacyAnnotationView = [self.mapView viewForAnnotation:self.mkAnnotation];
    
    if (legacyAnnotationView)
    {
        [legacyAnnotationView prepareForReuse];
        
        MGSMarkerOptions options = self.markerOptions;
        
        BOOL frameIsValid = !((CGAffineTransformEqualToTransform(legacyAnnotationView.transform, CGAffineTransformIdentity) == NO) ||
                               CGRectIsNull(legacyAnnotationView.frame) ||
                               CGRectIsInfinite(legacyAnnotationView.frame) ||
                               CGRectIsEmpty(legacyAnnotationView.frame));
        
        CGRect originalFrame = legacyAnnotationView.bounds;
        CGRect drawingFrame = originalFrame;
        if (frameIsValid) {
            drawingFrame = originalFrame = legacyAnnotationView.frame;
            
            CGRect stdFrame = CGRectStandardize(legacyAnnotationView.frame);
            
            // Assume that any non-zero frame is centered by MKAnnotationView
            // and undo the centering
            if (!CGPointEqualToPoint(stdFrame.origin, CGPointZero)) {
                stdFrame = CGRectOffset(stdFrame, (CGRectGetWidth(originalFrame) / 2.0), (CGRectGetHeight(originalFrame) / 2.0));
            }
            
            drawingFrame = stdFrame;
        }
    
    
        if (!CGPointEqualToPoint(legacyAnnotationView.centerOffset, CGPointZero)) {
            drawingFrame = CGRectOffset(drawingFrame, legacyAnnotationView.centerOffset.x, legacyAnnotationView.centerOffset.y);
        }
    
    
        /* X:
         *  <0 -> Left on iOS, Left on ArcGIS
         *  >0 -> Right on iOS, right on ArcGIS
         * Y:
         *  <0 -> Up on iOS, Down on ArcGIS
         *  >0 -> Down on iOS, up on ArcGIS
         */
        options.offset = CGPointMake(CGRectGetMinX(drawingFrame),-CGRectGetMinY(drawingFrame));
        self.markerOptions = options;
    
        UIGraphicsBeginImageContextWithOptions(legacyAnnotationView.bounds.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        if (context) {
            legacyAnnotationView.layer.backgroundColor = [[UIColor clearColor] CGColor];
            [legacyAnnotationView.layer renderInContext:context];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        if (frameIsValid) {
            legacyAnnotationView.frame = originalFrame;
        }
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