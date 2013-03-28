#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSLayer.h"
#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"
#import "MGSSafeAnnotation.h"


@interface MGSLayer () <AGSLayerDelegate>
@property (nonatomic,strong) NSMutableOrderedSet *layerAnnotations;

- (void)insertAnnotation:(id<MGSAnnotation>)annotation atIndex:(NSUInteger)index;
- (void)deleteAnnotations:(NSOrderedSet *)annotations
     shouldNotifyDelegate:(BOOL)notifyDelegate;
- (void)addAnnotations:(NSOrderedSet *)annotations
  shouldNotifyDelegate:(BOOL)notifyDelegate;
@end

@implementation MGSLayer
@dynamic annotations;

#pragma mark - Class Methods

+ (MKCoordinateRegion)regionForAnnotations:(NSSet *)annotations {
    NSMutableArray *coordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations) {
        MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        switch (safeAnnotation.annotationType) {
            case MGSAnnotationMarker:
            case MGSAnnotationPointOfInterest: {
                [coordinates addObject:[NSValue valueWithCLLocationCoordinate:safeAnnotation.coordinate]];
            }
                break;
                
            case MGSAnnotationPolygon:
            case MGSAnnotationPolyline: {
                if ([safeAnnotation.points count]) {
                    [coordinates addObjectsFromArray:safeAnnotation.points];
                }
            }
                break;
        }
    }
    
    return MKCoordinateRegionForCoordinates([NSSet setWithArray:coordinates]);
}

- (id)init {
    return [self initWithName:nil];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        self.name = name;
        self.layerAnnotations = [[NSMutableOrderedSet alloc] init];
    }
    
    return self;
}

#pragma mark - Property Accessor/Mutators
- (void)setAnnotations:(NSArray *)annotations {
    if (self.annotations) {
        [self deleteAllAnnotations];
    }
    
    [self addAnnotations:annotations];
}

- (NSOrderedSet *)annotations {
    return [NSOrderedSet orderedSetWithOrderedSet:self.layerAnnotations];
}

#pragma mark - Public Methods
- (void)addAnnotation:(id <MGSAnnotation>)annotation {
    [self addAnnotations:[NSOrderedSet orderedSetWithObject:annotation]
    shouldNotifyDelegate:YES];
}

- (void)addAnnotations:(NSArray *)annotations {
    [self addAnnotations:[NSOrderedSet orderedSetWithArray:annotations]
    shouldNotifyDelegate:YES];
}

- (void)addAnnotations:(NSOrderedSet *)annotations
  shouldNotifyDelegate:(BOOL)notifyDelegate
{
    if ([annotations count]) {

        // Check out current annotations and delete any which
        // are in the array of annotations we are adding.
        // The logic here is that we are assuming that attempting
        // to re-add an existing annotation will result in a
        // refresh of that annotation
        NSMutableOrderedSet* refreshedAnnotations = [self.layerAnnotations mutableCopy];
        [refreshedAnnotations intersectSet:[annotations set]];

        [self deleteAnnotations:refreshedAnnotations
           shouldNotifyDelegate:NO];

        if (notifyDelegate) {
            [self willAddAnnotations:[annotations array]];
        }

        [self willChangeValueForKey:@"annotations"];
        [self.layerAnnotations addObjectsFromArray:annotations];
        [self didChangeValueForKey:@"annotations"];

        if (notifyDelegate) {
            [self didAddAnnotations:[annotations array]];
        }
    }
}

- (void)deleteAllAnnotations {
    [self deleteAnnotations:self.layerAnnotations
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotation:(id <MGSAnnotation>)annotation {
    [self deleteAnnotations:[NSOrderedSet orderedSetWithObject:annotation]
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotations:(NSArray *)annotations
{
    [self deleteAnnotations:[NSOrderedSet orderedSetWithArray:annotations]
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotations:(NSOrderedSet *)annotations
     shouldNotifyDelegate:(BOOL)notifyDelegate
{
    if ([annotations count]) {
        NSMutableOrderedSet *deletedAnnotations = [annotations mutableCopy];
        [deletedAnnotations intersectSet:[self.layerAnnotations set]];

        if (notifyDelegate) {
            [self willRemoveAnnotations:[deletedAnnotations array]];
        }

        [self willChangeValueForKey:@"annotations"];
        [self.layerAnnotations minusOrderedSet:deletedAnnotations];
        [self didChangeValueForKey:@"annotations"];

        if (notifyDelegate) {
            [self didRemoveAnnotations:[deletedAnnotations array]];
        }
    }
}

- (MKCoordinateRegion)regionForAnnotations {
    return [MGSLayer regionForAnnotations:[self.layerAnnotations set]];
}

#pragma mark - Map Layer Delegation
- (void)willAddAnnotations:(NSArray *)annotations {
    [self willChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:willAddAnnotations:)]) {
        [self.delegate mapLayer:self
             willAddAnnotations:annotations];
    }
}

- (void)didAddAnnotations:(NSArray *)annotations {
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:didAddAnnotations:)]) {
        [self.delegate mapLayer:self
              didAddAnnotations:annotations];
    }
}

- (void)willRemoveAnnotations:(NSArray *)annotations {
    [self willChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSArray *)annotations {
    [self didChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:didRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
           didRemoveAnnotations:annotations];
    }
}

@end
