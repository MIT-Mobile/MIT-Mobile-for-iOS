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
    
    if (self.legacyAnnotationView)
    {
        UIView *annotationView = self.legacyAnnotationView;
        
        CGRect superRect = CGRectZero;
        CGRect annotationRect = annotationView.frame;
        superRect.size = annotationView.frame.size;
        
        if (annotationView.frame.origin.x < 0)
        {
            superRect.size.width += fabs(annotationView.frame.origin.x);
            annotationRect.origin.x = 0.0;
        }
        
        if (annotationView.frame.origin.y < 0)
        {
            superRect.size.height += fabs(annotationView.frame.origin.y);
            annotationRect.origin.y = 0.0;
        }
        
        UIView *superView = [[UIView alloc] initWithFrame:superRect];
        annotationView.frame = annotationRect;
        
        [superView addSubview:annotationView];
        [superView layoutIfNeeded];
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(superView.frame.size.width, superView.frame.size.height), NO, 0.0);
        superView.layer.backgroundColor = [[UIColor clearColor] CGColor];
        [superView.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [annotationView removeFromSuperview];
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