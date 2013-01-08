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

- (UIImage*)annotationMarker
{
    __block UIImage *image = nil;
    
    if (self.legacyAnnotationView)
    {
        UIView *annotationView = self.legacyAnnotationView;
        CALayer *annotationLayer = annotationView.layer;
        
        CGRect rect = annotationView.frame;
        rect.origin = CGPointZero;
        annotationView.frame = rect;
        [annotationView layoutIfNeeded];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            annotationLayer.backgroundColor = [[UIColor blackColor] CGColor];
            
            //CGSize size = CGSizeMake(CGRectGetWidth(annotationView.frame) - CGRectGetMinX(annotationView.frame),
            //                         CGRectGetHeight(annotationView.frame) - CGRectGetMinY(annotationView.frame));
            UIGraphicsBeginImageContextWithOptions(annotationView.bounds.size, YES, 0.0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            // Center the context around the view's anchor point
            CGContextTranslateCTM(context, [annotationView center].x, [annotationView center].y);
            // Apply the view's transform about the anchor point
            CGContextConcatCTM(context, [annotationView transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[annotationView bounds].size.width * [annotationLayer anchorPoint].x,
                                  -[annotationView bounds].size.height * [annotationLayer anchorPoint].y);
            
            [annotationLayer.presentationLayer renderInContext:context];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
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