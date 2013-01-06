#import "MGSAnnotationSymbol.h"
#import "MGSLayerAnnotation.h"

@interface MGSAnnotationSymbol ()
@property (nonatomic,strong) id<MGSAnnotation> annotation;
@property (nonatomic,strong) UIImage *cachedImage;
@end

@implementation MGSAnnotationSymbol
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
{
    return [self initWithAnnotation:annotation
                   defaultImageName:@"map/map_pin_complete"];
}

- (id)initWithAnnotation:(id<MGSAnnotation>)layerAnnotation defaultImageName:(NSString *)imageName
{
    self = [super initWithImageNamed:imageName];
    
    if (self)
    {
        self.annotation = layerAnnotation;
    }
    
    return self;
}

- (UIImage*)image
{
    UIView *annotationView = self.annotation.annotationView;
    
    if (annotationView)
    {
        CGRect frame = annotationView.frame;
        frame.origin = CGPointZero;
        annotationView.frame = frame;
        
        [annotationView layoutIfNeeded];
        CALayer *annotationLayer = annotationView.layer;
        
        if ((self.cachedImage == nil) || annotationLayer.needsDisplay)
        {
            CGSize size = CGSizeMake(annotationView.frame.size.height, annotationView.frame.size.width);
            UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextConcatCTM(context, annotationView.transform);
            [annotationLayer renderInContext:context];
            self.cachedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        return self.cachedImage;
    }
    
    UIImage *image = [super image];
    return image;
}

- (void)setAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation isEqual:_annotation] == NO)
    {
        _annotation = annotation;
        self.cachedImage = nil;
    }
}

- (BOOL)shouldCacheSymbol
{
    return NO;
}
@end
