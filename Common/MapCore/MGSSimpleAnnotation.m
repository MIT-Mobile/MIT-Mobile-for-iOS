#import "MGSSimpleAnnotation.h"

@implementation MGSSimpleAnnotation
- (id)init {
    return [self initWithAnnotationType:MGSAnnotationMarker];
}

- (id)initWithAnnotationType:(MGSAnnotationType)type
{
    self = [super init];
    
    if (self) {
        self.markerOptions = MGSMarkerOptionsMake(CGPointMake(0.0, 0.0), CGPointMake(0.0, 0.0));
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    MGSSimpleAnnotation *copy = [[[self class] alloc] init];
    
    if (copy) {
        copy.annotationType = self.annotationType;
        copy.calloutImage = self.calloutImage;
        copy.coordinate = self.coordinate;
        copy.detail = self.detail;
        copy.fillColor = self.fillColor;
        copy.lineWidth = self.lineWidth;
        copy.markerImage = self.markerImage;
        copy.markerOptions = self.markerOptions;
        copy.points = self.points;
        copy.strokeColor = self.strokeColor;
        copy.title = self.title;
        copy.userData = self.userData;
    }
    
    return copy;
}

@end
