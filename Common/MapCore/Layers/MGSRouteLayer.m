#import <CoreFoundation/CoreFoundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSRouteLayer.h"
#import "MGSSimpleAnnotation.h"
#import "MGSUtility.h"

@interface MGSRouteLayer ()
@property (nonatomic,strong) NSArray *pathCoordinates;
@property (nonatomic,strong) NSOrderedSet *stops;
@property (nonatomic,strong) id<MGSAnnotation> routePath;
@property (nonatomic,assign) CGFloat lineWidth;
@property (nonatomic,strong) UIColor *lineColor;
@end

@implementation MGSRouteLayer
- (id)initWithName:(NSString *)name withStops:(NSOrderedSet*)stopAnnotations {
    self = [super initWithName:name];

    if (self)
    {
        self.stops = stopAnnotations;
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
        self.stops = stopAnnotations;
        self.pathCoordinates = pathCoordinates;
        self.lineColor = [UIColor redColor];
        self.lineWidth = 4.0f;
        NSMutableOrderedSet *annotations = [NSMutableOrderedSet orderedSetWithOrderedSet:stopAnnotations];
        
        if ([pathCoordinates count]) {
            MGSSimpleAnnotation *routeAnnotation = [[MGSSimpleAnnotation alloc] init];
            routeAnnotation.annotationType = MGSAnnotationPolyline;
            routeAnnotation.strokeColor = self.lineColor;
            routeAnnotation.lineWidth = self.lineWidth;
            routeAnnotation.points = self.pathCoordinates;
            
            [annotations insertObject:routeAnnotation
                              atIndex:0];
        }
        
        self.annotations = annotations;
    }
    
    return self;
}

@end
