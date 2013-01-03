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
        [annotationView layoutIfNeeded];
        CALayer *annotationLayer = annotationView.layer;
        
        if ((self.cachedImage == nil) || annotationLayer.needsDisplay)
        {
            UIGraphicsBeginImageContextWithOptions(annotationView.frame.size, NO, [[UIScreen mainScreen] scale]);
            [annotationLayer renderInContext:UIGraphicsGetCurrentContext()];
            self.cachedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        return self.cachedImage;
    }
    
    UIImage *image = [super image];
    NSLog(@"%@", NSStringFromCGSize(image.size));
    return image;
}

/*
- (CGSize)drawingSize
{
    UIView *annotationView = self.annotation.annotationView;
    CGSize size = CGSizeZero;
    
    if (annotationView)
    {
        CGSize size = annotationView.frame.size;
        return size;
    }
    else
    {
        if ([super respondsToSelector:@selector(drawingSize)])
        {
            return [super drawingSize];
        }
    }
}
 */

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
