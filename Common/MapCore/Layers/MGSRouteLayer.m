#import <CoreFoundation/CoreFoundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSRouteLayer.h"
#import "MGSSimpleAnnotation.h"
#import "MGSUtility.h"

@interface MGSRouteLayer ()
@property (nonatomic,strong) NSArray *pathCoordinates;
@property (nonatomic,strong) NSOrderedSet *stopAnnotations;
@property (nonatomic,strong) id<MGSAnnotation> routePath;
@property (nonatomic,weak) AGSGraphic *lineGraphic;
@end

@implementation MGSRouteLayer
- (id)initWithName:(NSString *)name withStops:(NSOrderedSet*)stopAnnotations {
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

- (id)initWithName:(NSString*)name withStops:(NSOrderedSet*)stopAnnotations pathCoordinates:(NSArray*)pathCoordinates
{
    self = [super initWithName:name];
    
    if (self)
    {
        self.stopAnnotations = stopAnnotations;
        self.pathCoordinates = pathCoordinates;
        self.lineColor = [UIColor redColor];
        self.lineWidth = 4.0f;
        
        NSMutableOrderedSet *annotations = [NSMutableOrderedSet orderedSet];
        [annotations unionOrderedSet:stopAnnotations];
        [annotations insertObject:self.routePath
                          atIndex:0];
        [self addAnnotations:annotations];
    }
    
    return self;
}

- (void)setAnnotations:(NSOrderedSet *)annotations
{
    if (self.routePath) {
        NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
        [newAnnotations unionOrderedSet:annotations];
        [newAnnotations insertObject:self.routePath
                             atIndex:0];
        [super setAnnotations:newAnnotations];
    } else {
        [super setAnnotations:annotations];
    }
}
        
        

- (id<MGSAnnotation>)routePath
{
    if ((_routePath == nil) && [self.pathCoordinates count]) {
        MGSSimpleAnnotation *routeAnnotation = [[MGSSimpleAnnotation alloc] init];
        routeAnnotation.annotationType = MGSAnnotationPolyline;
        routeAnnotation.strokeColor = self.lineColor;
        routeAnnotation.lineWidth = self.lineWidth;
        routeAnnotation.points = self.pathCoordinates;
        
        _routePath = routeAnnotation;
    }
    
    return _routePath;
}

@end
