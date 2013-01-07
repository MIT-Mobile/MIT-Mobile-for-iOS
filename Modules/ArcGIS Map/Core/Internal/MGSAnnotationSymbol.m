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
            self.xoffset = -annotationView.frame.origin.x;
            self.yoffset = -annotationView.frame.origin.y;
            CGSize size = CGSizeMake(annotationView.frame.size.width,
                                     annotationView.frame.size.height);
            
            UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [annotationView center].x, [annotationView center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [annotationView transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[annotationView bounds].size.width * [annotationLayer anchorPoint].x,
                                  -[annotationView bounds].size.height * [annotationLayer anchorPoint].y);

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
