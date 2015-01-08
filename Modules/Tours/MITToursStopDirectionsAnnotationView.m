#import "MITToursStopDirectionsAnnotationView.h"
#import "MITToursStopDirectionAnnotation.h"

@implementation MITToursStopDirectionsAnnotationView

- (instancetype)initWithStopDirectionAnnotation:(MITToursStopDirectionAnnotation *)stopAnnotation
{
    self = [super init];
    if (self) {
        self.annotation = stopAnnotation;
        [self setupImageView];
    }
    
    return self;
}

- (void)setupImageView
{
    MITToursStopDirectionAnnotation *stopAnnotation = (MITToursStopDirectionAnnotation *)self.annotation;
    
    NSString *imageName = stopAnnotation.isDestination ? @"tours-annotation-arrow-end" : @"tours-annotation-arrow-start";
    UIImageView *directionArrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    
    // Create and apply a rotation to the arrow view in order to
    // have it appear properly (the start should be coming from the current annotation
    // and end should be pointing at the next stop). Since all rotations
    // start from (0,0), not the center of the image, we need to
    // translate the view so that the image is centered around (0,0),
    // then do the rotation, then translate the result back
    CGFloat deltaX = CGRectGetMidX(directionArrowView.frame);
    CGFloat deltaY = CGRectGetMidY(directionArrowView.frame);
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-deltaX, -deltaY);
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(stopAnnotation.directionArrowRotationDegrees);
    transform = CGAffineTransformConcat(transform, rotationTransform);
    transform = CGAffineTransformTranslate(transform, deltaX, deltaY);
    
    directionArrowView.transform = transform;
    
    [self addSubview:directionArrowView];
    
    self.frame = CGRectOffset(directionArrowView.bounds, deltaX, deltaY);
    
    self.canShowCallout = NO;
}

@end
