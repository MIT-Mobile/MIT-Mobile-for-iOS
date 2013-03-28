#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSLayer+Subclass.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"

#import "MGSMapView.h"

#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"
#import "MGSCalloutView.h"

@interface MGSLayer () <AGSLayerDelegate>
@property (nonatomic,strong) NSMutableArray *layerAnnotations;

- (void)insertAnnotation:(id<MGSAnnotation>)annotation atIndex:(NSUInteger)index;
@end

@implementation MGSLayer
@dynamic annotations;
@dynamic hasGraphicsLayer;

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
        self.layerAnnotations = [NSMutableArray array];
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

- (NSArray *)annotations {
    NSMutableArray *extAnnotations = [NSMutableArray array];
    for (MGSLayerAnnotation *annotation in self.layerAnnotations) {
        [extAnnotations addObject:annotation.annotation];
    }
    
    return extAnnotations;
}

#pragma mark - Public Methods
- (void)addAnnotation:(id <MGSAnnotation>)annotation {
    [self addAnnotations:@[ annotation ]];
}

- (void)addAnnotations:(NSArray *)annotations {
    NSMutableArray *newAnnotations = [NSMutableArray arrayWithArray:annotations];
    [newAnnotations removeObjectsInArray:self.annotations];
    
    if ([newAnnotations count]) {
        [self willAddAnnotations:newAnnotations];
        
        // Sort the add order of the annotations so they are added
        // top to bottom (prevents higher markers from being overlayed
        // on top of lower ones) and left to right
        NSArray *sortedAnnotations = [newAnnotations sortedArrayUsingComparator:^NSComparisonResult(id <MGSAnnotation> obj1, id <MGSAnnotation> obj2) {
            CLLocationCoordinate2D point1 = obj1.coordinate;
            CLLocationCoordinate2D point2 = obj2.coordinate;
            
            if (point1.latitude > point2.latitude) {
                return NSOrderedAscending;
            }
            else if (point1.latitude < point2.latitude) {
                return NSOrderedDescending;
            }
            else if (point1.longitude > point2.longitude) {
                return NSOrderedDescending;
            }
            else if (point1.longitude < point2.longitude) {
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }];
        
        for (id <MGSAnnotation> annotation in sortedAnnotations) {
            MGSLayerAnnotation *mapAnnotation = nil;
            
            if ([annotation isKindOfClass:[MGSLayerAnnotation class]]) {
                mapAnnotation = (MGSLayerAnnotation *) annotation;
                
                // Make sure some other layer doesn't already have a claim on this
                // annotation and, if one does, we need to create a new layer annotation
                // which wraps the annotation we are working with
                if ((mapAnnotation.layer != nil) && (mapAnnotation.layer != self)) {
                    mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:mapAnnotation.annotation
                                                                           graphic:nil];
                }
            }
            
            if (mapAnnotation == nil) {
                mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                       graphic:nil];
            }
            
            mapAnnotation.layer = self;
            
            [self.layerAnnotations addObject:mapAnnotation];
        }
        
        [self didAddAnnotations:newAnnotations];
    }
}

- (void)insertAnnotation:(id<MGSAnnotation>)annotation atIndex:(NSUInteger)index {
    MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
    if (layerAnnotation) {
        [self.layerAnnotations removeObject:layerAnnotation];
    } else {
        [self willAddAnnotations:@[annotation]];
        
        if ([annotation isKindOfClass:[MGSLayerAnnotation class]]) {
            MGSLayerAnnotation *existingAnnotation = (MGSLayerAnnotation *) annotation;
            
            // Make sure some other layer doesn't already have a claim on this
            // annotation and, if one does, we need to create a new layer annotation
            // which wraps the annotation we are working with
            if ((existingAnnotation.layer != nil) && (existingAnnotation.layer != self)) {
                layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:existingAnnotation.annotation
                                                                         graphic:nil];
            }
        }
        
        if (layerAnnotation == nil) {
            layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                     graphic:nil];
        }
        
        layerAnnotation.layer = self;
        
        [self didAddAnnotations:@[annotation]];
    }
    
    [self.layerAnnotations insertObject:layerAnnotation
                                atIndex:index];
    
}

- (void)deleteAnnotation:(id <MGSAnnotation>)annotation {
    if (annotation && [self.layerAnnotations containsObject:annotation]) {
        if ([self.mapView.calloutAnnotation isEqual:annotation]) {
            [self.mapView dismissCallout];
        }
        
        MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
        layerAnnotation.layer = nil;
        [self.graphicsLayer removeGraphic:layerAnnotation.graphic];
        [self.layerAnnotations removeObject:layerAnnotation];
    }
}

- (void)deleteAnnotations:(NSArray *)annotations {
    if ([annotations count]) {
        [self willRemoveAnnotations:annotations];
        
        for (id <MGSAnnotation> annotation in annotations) {
            MGSLayerAnnotation *mapAnnotation = [self layerAnnotationForAnnotation:annotation];
            
            [self.layerAnnotations removeObject:mapAnnotation];
            [self.graphicsLayer removeGraphic:mapAnnotation.graphic];
        }
        
        [self didRemoveAnnotations:annotations];
    }
}

- (void)deleteAllAnnotations {
    [self deleteAnnotations:self.annotations];
}

- (void)centerOnAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.annotations containsObject:annotation]) {
        [self.mapView centerAtCoordinate:annotation.coordinate];
    }
}

- (MKCoordinateRegion)regionForAnnotations {
    return [MGSLayer regionForAnnotations:[NSSet setWithArray:self.layerAnnotations]];
}

#pragma mark - Class Extension methods
- (MGSLayerAnnotation *)layerAnnotationForAnnotation:(id <MGSAnnotation>)annotation {
    __block void *layerAnnotation = nil;
    
    // Using OSAtomicCompareAndSwapPtrBarrier so we have atomic pointer
    // assignments since the array is going to be enumerated concurrently
    // and I'd rather not deal with odd race conditions since a standard
    // if-nil-else is not atomic.
    [self.layerAnnotations enumerateObjectsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(MGSLayerAnnotation *obj, NSUInteger idx, BOOL *stop) {
                                                if ([obj.annotation isEqual:annotation]) {
                                                    (*stop) = YES;
                                                    OSAtomicCompareAndSwapPtrBarrier(nil, (__bridge void *) (obj), &layerAnnotation);
                                                }
                                            }];
    
    return (__bridge MGSLayerAnnotation *) layerAnnotation;
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
    [self didChangeValueForKey:@"annotations"];
    
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
