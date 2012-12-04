#import <ArcGIS/ArcGIS.h>

#import "MGSMapLayer.h"
#import "MGSLayerAnnotation.h"

#import "MGSMapView.h"
#import "MGSAnnotation.h"

#import "MGSMarker.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

#import "MGSMapLayer+Protected.h"
#import "MGSUtility.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

@interface NSURLRequest (NSURLRequestWithIgnoreSSL)
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
@end

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
}
@end

@interface MGSMapLayer ()
@property (nonatomic, strong) NSMutableArray *mutableAnnotations;
@end

@implementation MGSMapLayer
@dynamic annotations;
@dynamic hasGraphicsLayer;

- (id)init
{
    return [self initWithName:nil];
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        self.name = name;
        self.mutableAnnotations = [NSMutableArray array];
    }
    
    return self;
}

- (void)setAnnotations:(NSArray *)annotations
{
    if (self.annotations)
    {
        [self deleteAllAnnotations];
    }
    
    [self addAnnotations:[NSSet setWithArray:annotations]];
}

- (NSArray*)annotations
{
    NSMutableArray *extAnnotations = [NSMutableArray array];
    for (MGSLayerAnnotation *annotation in extAnnotations)
    {
        [extAnnotations addObject:annotation.annotation];
    }
    
    return extAnnotations;
}

#pragma mark - Public Methods
- (void)addAnnotation:(id<MGSAnnotation>)annotation
{
    [self addAnnotations:[NSSet setWithObject:annotation]];
}

- (void)addAnnotations:(NSSet*)annotations
{
    NSMutableSet *newSet = [NSMutableSet setWithSet:annotations];
    [newSet minusSet:[NSSet setWithArray:self.annotations]];
    
    if ([newSet count])
    {
        [self willAddAnnotations:newSet];
        
        for (id<MGSAnnotation> annotation in newSet)
        {
            AGSGraphic *graphic = [MGSIMapAnnotation graphicForAnnotation:annotation
                                                                 template:self.markerTemplate];
            
            MGSLayerAnnotation *mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                       graphic:graphic];
            
            [graphic.attributes setObject:mapAnnotation
                                   forKey:MGSAnnotationAttributeKey];
            
            [self.mutableAnnotations addObject:mapAnnotation];
            [self.graphicsLayer addGraphic:graphic];
        }
        
        [self didAddAnnotations:newSet];
    }
}

- (void)deleteAnnotation:(id<MGSAnnotation>)annotation
{
    if (annotation && [self.mutableAnnotations containsObject:annotation])
    {
        if ([self.mapView isPresentingCalloutForAnnotation:annotation])
        {
            [self.mapView hideCallout];
        }
        
        MGSLayerAnnotation *layerAnnotation = [self.mutableAnnotations objectAtIndex:[self.mutableAnnotations indexOfObject:annotation]];
        [self.graphicsLayer removeGraphic:layerAnnotation.graphic];
        [self.mutableAnnotations removeObject:layerAnnotation];
    }
}

- (void)deleteAnnotations:(NSSet *)annotations
{
    if ([annotations count])
    {
        [self willRemoveAnnotations:annotations];
        
        for (id<MGSAnnotation> annotation in annotations)
        {
            MGSLayerAnnotation *mapAnnotation = [self.mutableAnnotations objectAtIndex:[self.mutableAnnotations indexOfObject:annotation]];
            
            [self.graphicsLayer removeGraphic:mapAnnotation.graphic];
            [mapAnnotation.graphic.attributes removeObjectForKey:MGSAnnotationAttributeKey];
            [self.mutableAnnotations removeObject:mapAnnotation];
        }
        
        [self didRemoveAnnotations:annotations];
    }
}

- (void)deleteAllAnnotations
{
    for (id<MGSAnnotation> annotation in self.annotations)
    {
        [self deleteAnnotation:annotation];
    }
}

#pragma mark - ArcGIS Methods
- (AGSGraphicsLayer*)graphicsLayer
{
    if (_graphicsLayer == nil)
    {
        [self loadGraphicsLayer];
    }
    
    return _graphicsLayer;
}

- (void)loadGraphicsLayer
{
    AGSGraphicsLayer *graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    
    for (MGSLayerAnnotation *annotation in self.mutableAnnotations)
    {
        AGSGraphic *graphic = nil;
        
        if (annotation.graphic)
        {
            graphic = annotation.graphic;
        }
        else
        {
            graphic = [MGSIMapAnnotation graphicForAnnotation:annotation.annotation
                                                     template:self.markerTemplate];
            [graphic.attributes setObject:annotation
                                   forKey:MGSAnnotationAttributeKey];
            annotation.graphic = graphic;
        }
        
        [graphicsLayer addGraphic:graphic];
    }
    
    [self setGraphicsLayer:graphicsLayer];
}

- (BOOL)hasGraphicsLayer
{
    return (_graphicsLayer != nil);
}

- (void)refreshLayer
{
    AGSSpatialReference *graphicsReference = self.graphicsLayer.spatialReference;
    AGSSpatialReference *viewReference = self.graphicsView.mapView.spatialReference;
    BOOL referencesEqual = [graphicsReference isEqualToSpatialReference:viewReference];
    
    if (graphicsReference && viewReference && (referencesEqual == NO))
    {
        DDLogVerbose(@"Converting %@ to %@", graphicsReference, viewReference);
        
        for (AGSGraphic *graphic in self.graphicsLayer.graphics)
        {
            // Only reproject on a spatial reference mismatch
            if ([graphic.geometry.spatialReference isEqualToSpatialReference:viewReference] == NO)
            {
                graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                           toSpatialReference:viewReference];
            }
        }
    }

    [self.graphicsLayer dataChanged];
}

- (void)setHidden:(BOOL)hidden
{
    if (_hidden != hidden)
    {
        _hidden = hidden;
        self.graphicsView.hidden = hidden;
    }
}

#pragma mark - Map Layer Delegation
- (void)willMoveToMapView:(MGSMapView*)mapView
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)])
    {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)didMoveToMapView:(MGSMapView*)mapView
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)])
    {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)willAddAnnotations:(NSSet*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willAddAnnotations:)])
    {
        [self.delegate mapLayer:self
             willAddAnnotations:annotations];
    }
}

- (void)didAddAnnotations:(NSSet*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didAddAnnotations:)])
    {
        [self.delegate mapLayer:self
              didAddAnnotations:annotations];
    }
}

- (void)willRemoveAnnotations:(NSSet*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)])
    {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSSet*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didRemoveAnnotations:)])
    {
        [self.delegate mapLayer:self
           didRemoveAnnotations:annotations];
    }
}

- (void)willReloadMapLayer
{
    if ([self.delegate respondsToSelector:@selector(willReloadMapLayer:)])
    {
        [self.delegate willReloadMapLayer:self];
    }
}

- (BOOL)shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:shouldDisplayCalloutForAnnotation:)])
    {
        return [self.delegate mapLayer:self
            shouldDisplayCalloutForAnnotation:annotation];
    }
    
    return YES;
}

- (void)willDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willDisplayCalloutForAnnotation:)])
    {
        [self.delegate mapLayer:self
            willDisplayCalloutForAnnotation:annotation];
    }
}

- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:calloutViewForAnnotation:)])
    {
        return [self.delegate mapLayer:self
              calloutViewForAnnotation:annotation];
    }
    
    return nil;
}

- (void)calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:calloutAccessoryDidReceiveTapForAnnotation:)])
    {
        [self.delegate mapLayer:self
            calloutAccessoryDidReceiveTapForAnnotation:annotation];
    }
}

- (void)didPresentCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didPresentCalloutForAnnotation:)])
    {
        [self.delegate mapLayer:self
            didPresentCalloutForAnnotation:annotation];
    }
}

@end
