#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSLayer.h"
#import "MGSGeometry.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"
#import "MGSSafeAnnotation.h"


@interface MGSLayer () <AGSLayerDelegate>
@property (nonatomic,strong) NSMutableOrderedSet *layerAnnotations;

- (void)addAnnotations:(NSOrderedSet *)annotations
  shouldNotifyDelegate:(BOOL)notifyDelegate;

- (void)deleteAnnotations:(NSSet *)annotations
     shouldNotifyDelegate:(BOOL)notifyDelegate;
@end

@implementation MGSLayer
@dynamic annotations;

#pragma mark - Class Methods

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic;
    NSSet *manualKeys = [NSSet setWithArray:@[@"annotations"]];

    if ([manualKeys containsObject:theKey]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }

    return automatic;
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
- (void)setAnnotationWithArray:(NSArray*)annotations
{
    [self setAnnotations:[NSOrderedSet orderedSetWithArray:annotations]];
}

- (void)setAnnotations:(NSOrderedSet *)annotations {
    if (self.annotations) {
        [self deleteAllAnnotations];
    }
    
    [self addAnnotations:annotations
    shouldNotifyDelegate:YES];
}

- (NSOrderedSet *)annotations {
    return [NSOrderedSet orderedSetWithOrderedSet:self.layerAnnotations];
}

#pragma mark - Public Methods
- (void)insertAnnotation:(id<MGSAnnotation>)annotation
                 atIndex:(NSUInteger)index
{
    if ([self.layerAnnotations containsObject:annotation] == NO) {
        [self willChangeValueForKey:@""];
    }
}

- (void)addAnnotation:(id <MGSAnnotation>)annotation {
    [self addAnnotations:[NSOrderedSet orderedSetWithObject:annotation]
    shouldNotifyDelegate:YES];
}

- (void)addAnnotations:(NSArray *)annotations {
    [self addAnnotations:[NSOrderedSet orderedSetWithArray:annotations]
    shouldNotifyDelegate:YES];
}

- (void)addAnnotationsFromOrderedSet:(NSOrderedSet*)annotations
{
    [self addAnnotations:annotations
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

        [self deleteAnnotations:[refreshedAnnotations set]
           shouldNotifyDelegate:NO];

        if (notifyDelegate) {
            [self willAddAnnotations:[annotations array]];
        }

        [self willChangeValueForKey:@"annotations"];
        [self.layerAnnotations addObjectsFromArray:[annotations array]];
        [self didChangeValueForKey:@"annotations"];

        if (notifyDelegate) {
            [self didAddAnnotations:[annotations array]];
        }
    }
}

- (void)deleteAllAnnotations {
    [self deleteAnnotations:[self.layerAnnotations set]
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotation:(id <MGSAnnotation>)annotation {
    [self deleteAnnotations:[NSSet setWithObject:annotation]
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotations:(NSArray *)annotations
{
    [self deleteAnnotations:[NSSet setWithArray:annotations]
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotationsFromSet:(NSSet*)annotations
{
    [self deleteAnnotations:annotations
       shouldNotifyDelegate:YES];
}

- (void)deleteAnnotations:(NSSet*)annotations
     shouldNotifyDelegate:(BOOL)notifyDelegate
{
    if ([annotations count]) {
        NSMutableSet *deletedAnnotations = [annotations mutableCopy];
        [deletedAnnotations intersectSet:[self.layerAnnotations set]];

        if (notifyDelegate) {
            [self willRemoveAnnotations:[deletedAnnotations allObjects]];
        }

        [self willChangeValueForKey:@"annotations"];
        [self.layerAnnotations minusSet:deletedAnnotations];
        [self didChangeValueForKey:@"annotations"];

        if (notifyDelegate) {
            [self didRemoveAnnotations:[deletedAnnotations allObjects]];
        }
    }
}

- (MKCoordinateRegion)regionForAnnotations {
    return MKCoordinateRegionForMGSAnnotations([self.layerAnnotations set]);
}

#pragma mark - Map Layer Delegation
- (void)willAddAnnotations:(NSArray *)annotations {
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
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSArray *)annotations {
    if ([self.delegate respondsToSelector:@selector(mapLayer:didRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
           didRemoveAnnotations:annotations];
    }
}


- (void)willAddLayerToMapView:(MGSMapView*)mapView
{
    /* Do nothing, let a subclass override this */
}

- (void)didAddLayerToMapView:(MGSMapView*)mapView
{
    /* Do nothing, let a subclass override this */
}

- (void)willRemoveLayerFromMapView:(MGSMapView*)mapView
{
    /* Do nothing, let a subclass override this */
}

- (void)didRemoveLayerFromMapView:(MGSMapView*)mapView
{
    /* Do nothing, let a subclass override this */
}

@end
