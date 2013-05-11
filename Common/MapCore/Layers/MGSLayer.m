#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSLayer.h"
#import "MGSGeometry.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"
#import "MGSSafeAnnotation.h"


@implementation MGSLayer

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
    }
    
    return self;
}

#pragma mark - Property Accessor/Mutators
- (void)setAnnotations:(NSOrderedSet *)aAnnotations
{
    if ([_annotations isEqual:aAnnotations] == NO) {
        NSMutableOrderedSet *addedAnnotations = [aAnnotations mutableCopy];
        [addedAnnotations minusOrderedSet:_annotations];
        
        NSMutableOrderedSet *deletedAnnotations = [_annotations mutableCopy];
        [deletedAnnotations minusOrderedSet:aAnnotations];
        
        
        [self willAddAnnotations:addedAnnotations];
        [self willChangeValueForKey:@"annotations"];
        
        _annotations = aAnnotations;
        
        [self didChangeValueForKey:@"annotations"];
        [self didAddAnnotations:deletedAnnotations];
    }
}

#pragma mark - Public Methods
- (void)insertAnnotation:(id<MGSAnnotation>)annotation
                 atIndex:(NSUInteger)index
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations insertObject:annotation
                         atIndex:index];
    self.annotations = newAnnotations;
}

- (void)addAnnotation:(id <MGSAnnotation>)aAnnotation
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations addObject:aAnnotation];
    self.annotations = newAnnotations;
}

- (void)addAnnotationsFromArray:(NSArray*)aAnnotations
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations addObjectsFromArray:aAnnotations];
    self.annotations = newAnnotations;
}

- (void)addAnnotations:(NSOrderedSet *)aAnnotations
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations unionOrderedSet:newAnnotations];
    self.annotations = newAnnotations;
}

- (void)deleteAllAnnotations {
    self.annotations = nil;
}

- (void)deleteAnnotation:(id <MGSAnnotation>)annotation {
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations removeObject:annotation];
    self.annotations = newAnnotations;
}

- (void)deleteAnnotationsFromArray:(NSArray *)annotations
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations minusOrderedSet:[NSOrderedSet orderedSetWithArray:annotations]];
    self.annotations = newAnnotations;
}

- (void)deleteAnnotationsFromSet:(NSSet*)annotations
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations minusSet:annotations];
    self.annotations = newAnnotations;
}

- (void)deleteAnnotations:(NSOrderedSet *)annotations
{
    NSMutableOrderedSet *newAnnotations = [NSMutableOrderedSet orderedSet];
    [newAnnotations unionOrderedSet:self.annotations];
    [newAnnotations minusOrderedSet:annotations];
    self.annotations = newAnnotations;
}

- (MKCoordinateRegion)regionForAnnotations {
    return MKCoordinateRegionForMGSAnnotations([self.annotations set]);
}

#pragma mark - Map Layer Delegation
- (void)willAddAnnotations:(NSOrderedSet *)annotations {
    if ([self.delegate respondsToSelector:@selector(mapLayer:willAddAnnotations:)]) {
        [self.delegate mapLayer:self
             willAddAnnotations:annotations];
    }
}

- (void)didAddAnnotations:(NSOrderedSet *)annotations {
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:didAddAnnotations:)]) {
        [self.delegate mapLayer:self
              didAddAnnotations:annotations];
    }
}

- (void)willRemoveAnnotations:(NSOrderedSet *)annotations {
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSOrderedSet *)annotations {
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
