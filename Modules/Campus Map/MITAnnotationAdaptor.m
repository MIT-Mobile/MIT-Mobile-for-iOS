#import <QuartzCore/QuartzCore.h>

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
    
    if (self.legacyAnnotationView && ([self.legacyAnnotationView isKindOfClass:[MITPinAnnotationView class]] == NO))
    {
        UIView *annotationView = self.legacyAnnotationView;
        
        [annotationView sizeToFit];
        CGRect annotationBounds = annotationView.bounds;
        MGSMarkerOptions options = self.markerOptions;
        CGPoint origin = annotationView.frame.origin;
        origin.x = -origin.x;
        origin.y = -origin.y;
        options.offset = origin;
        self.markerOptions = options;
        
        annotationView.frame = annotationBounds;
        
        UIGraphicsBeginImageContextWithOptions(annotationBounds.size, NO, 0.0);
        annotationView.layer.backgroundColor = [[UIColor clearColor] CGColor];
        [annotationView.layer renderInContext:UIGraphicsGetCurrentContext()];
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