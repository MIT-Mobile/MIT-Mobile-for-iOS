#import <CoreFoundation/CoreFoundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSRouteLayer.h"
#import "MGSUtility.h"

@interface MGSRouteLayer ()
@property (nonatomic,strong) NSArray *pathCoordinates;
@property (nonatomic,strong) NSArray *stopAnnotations;
@property (nonatomic,strong) id<MGSAnnotation> routePath;
@property (nonatomic,weak) AGSGraphic *lineGraphic;
@end

@implementation MGSRouteLayer
- (id)initWithName:(NSString *)name withStops:(NSArray*)stopAnnotations {
    self = [super initWithName:name];

    if (self)
    {
        self.stopAnnotations = stopAnnotations;
        self.pathCoordinates = nil;
        self.lineColor = [UIColor redColor];
        self.lineWidth = 4.0f;
    }
    
    return self;
}

- (id)initWithName:(NSString*)name withStops:(NSArray*)stopAnnotations pathCoordinates:(NSArray*)pathCoordinates
{
    self = [super initWithName:name];
    
    if (self)
    {
        self.stopAnnotations = stopAnnotations;
        self.pathCoordinates = pathCoordinates;
        self.lineColor = [UIColor redColor];
        self.lineWidth = 4.0f;
        
        [self addAnnotations:stopAnnotations];
    }
    
    return self;
}

- (NSArray*)annotations {
    NSMutableArray *annotations = [NSMutableArray arrayWithArray:[super annotations]];
    [annotations removeObject:self.routePath];

    return annotations;
}

- (void)willReloadMapLayer
{
    [super willReloadMapLayer];

    if ((self.routePath == nil) && [self.pathCoordinates count]) {
        MGSSimpleAnnotation *annotation = [[MGSSimpleAnnotation alloc] init];
        annotation.annotationType = MGSAnnotationPolyline;
        annotation.points = self.pathCoordinates;
        annotation.lineWidth = self.lineWidth;
        annotation.strokeColor = self.lineColor;
        self.routePath = annotation;
    }
    
    if (self.routePath) {
        // Make sure the route is *always* underneath everything else
        [self insertAnnotation:self.routePath
                       atIndex:0];
    }
}
@end
