#import <ArcGIS/ArcGIS.h>

#import "MGSMapLayer.h"

#import "MGSMapView.h"
#import "MGSMapAnnotation.h"
#import "MGSMapAnnotation+Protected.h"

#import "MGSMarker.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

#import "MGSMapLayer+AGS.h"
#import "MGSMapAnnotation+AGS.h"
#import "MGSMapCoordinate+AGS.h"

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
    
    for (MGSMapAnnotation *annotation in annotations)
    {
        [self addAnnotation:annotation];
    }
}

- (NSArray*)annotations
{
    return [NSArray arrayWithArray:self.mutableAnnotations];
}

#pragma mark - Public Methods
- (void)addAnnotation:(MGSMapAnnotation*)annotation
{
    if (annotation && ([self.mutableAnnotations containsObject:annotation] == NO))
    {
        if (annotation.marker.style != MGSMarkerStyleRemote)
        {
            if (annotation.agsGraphic.layer)
            {
                [annotation.agsGraphic.layer removeGraphic:annotation.agsGraphic];
                annotation.agsGraphic = nil;
            }
            
            annotation.agsGraphic = [MGSMapAnnotation graphicForAnnotation:annotation
                                                                  template:self.markerTemplate];
        }
        
        [self.graphicsLayer addGraphic:annotation.agsGraphic];
        [self.mutableAnnotations addObject:annotation];
        annotation.layer = self;
    }
}

- (void)deleteAnnotation:(MGSMapAnnotation*)annotation
{
    if (annotation && [self.mutableAnnotations containsObject:annotation])
    {
        if ([self.calloutController isPresentingCalloutForAnnotation:annotation])
        {
            [self.mapView hideCallout];
        }
        
        [self.graphicsLayer removeGraphic:annotation.agsGraphic];
        
        annotation.agsGraphic = nil;
        annotation.layer = nil;
        [self.mutableAnnotations removeObject:annotation];
    }
}

- (void)deleteAllAnnotations
{
    for (MGSMapAnnotation *annotation in self.annotations)
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
    
    for (MGSMapAnnotation *annotation in self.annotations)
    {
        AGSGraphic *graphic = nil;
        
        if (annotation.agsGraphic)
        {
            graphic = annotation.agsGraphic;
        }
        else
        {
            graphic = [MGSMapAnnotation graphicForAnnotation:annotation
                                                    template:self.markerTemplate];
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

@end
