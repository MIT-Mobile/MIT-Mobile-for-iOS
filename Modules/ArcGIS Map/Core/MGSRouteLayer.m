#import <CoreFoundation/CoreFoundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSRouteLayer.h"
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
        
        [self addAnnotations:stopAnnotations];
    }
    
    return self;
}

- (NSOrderedSet*)annotations {
    NSMutableOrderedSet *annotations = [[super annotations] mutableCopy];
    [annotations removeObject:self.routePath];

    return annotations;
}
@end
