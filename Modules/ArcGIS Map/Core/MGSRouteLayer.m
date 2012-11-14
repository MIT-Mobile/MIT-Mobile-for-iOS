#import "MGSRouteLayer.h"
#import "MGSMapAnnotation.h"

#import <ArcGIS/ArcGIS.h>
#import "MGSMapLayer+AGS.h"
#import "MGSMapAnnotation+AGS.h"
#import "MGSMapCoordinate+AGS.h"

#define MGSRoutingURL(map) [NSURL URLWithString:[NSString stringWithFormat:@"http://ims-pub.mit.edu/ArcGIS/rest/services/mobile/%@/NAServer/Route",map]]

@interface MGSRouteLayer () <AGSRouteTaskDelegate,AGSLocatorDelegate>
@property (strong) AGSRouteTask *routingTask;
@property (strong) AGSRouteTaskParameters *routingParameters;
@property (strong) NSArray *routingAnnotations;
@property (strong) NSArray *routingStops;
@property (strong) id routeCompleteBlock;
@property (strong) id routingOperation;

@property (strong) AGSLocator *locator;
@property (assign) NSInteger locatorCount;
@property (strong) NSMutableDictionary *locatedStops;
@property (strong) NSMutableArray *locatorOperations;
@end

@implementation MGSRouteLayer
@dynamic start;
@dynamic end;

- (id)initWithName:(NSString*)name
{
    self = [super initWithName:name];
    
    if (self)
    {
        NSURL *mapServiceURL = MGSRoutingURL(@"MIT_ROUTE_NETWORK");
        
        AGSRouteTask *task = [AGSRouteTask routeTaskWithURL:mapServiceURL];
        task.delegate = self;
        self.routingTask = task;
    }
    
    return self;
}

- (void)solveRouteOnCompletion:(void (^)(BOOL routeSuccess, NSError *error))completionBlock;
{
    if (([self.annotations count] >= 2) && (self.routingOperation == nil))
    {
        self.routingOperation = [self.routingTask retrieveDefaultRouteTaskParameters];
        DDLogVerbose(@"Dispatched retrieveDefaultRouteTaskParameters");
    }
}

#pragma mark - Dynamic Properties
- (MGSMapAnnotation*)start
{
    if ([self.annotations count])
    {
        return [self.annotations objectAtIndex:0];
    }
    
    return nil;
}

- (MGSMapAnnotation*)stop
{
    if ([self.annotations count])
    {
        return [self.annotations lastObject];
    }
    
    return nil;
}

#pragma mark - AGSRouteTaskDelegate
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didRetrieveDefaultRouteTaskParameters:(AGSRouteTaskParameters *)routeParams
{
    if (op == self.routingOperation)
    {
        self.routingParameters = routeParams;
        if (self.locator == nil)
        {
            AGSLocator *locator = [AGSLocator locatorWithURL:[NSURL URLWithString:@"http://ims-pub.mit.edu/ArcGIS/rest/services/mobile/MIT_SPACE_ROOMS_GEOCODE/GeocodeServer"]];
            locator.delegate = self;
            self.locator = locator;
        }
        
        self.locatorCount = [self.annotations count];
        [self.annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MGSMapAnnotation class]])
            {
                MGSMapAnnotation *annotation = (MGSMapAnnotation*)obj;
                AGSPoint *point = annotation.coordinate.agsPoint;
                
                if (point)
                {
                    [self.locatorOperations addObject:[self.locator addressForLocation:point
                                                                     maxSearchDistance:10.0]];
                }
            }
        }];
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailToRetrieveDefaultRouteTaskParametersWithError:(NSError *)error
{
    if (op == self.routingOperation)
    {
        DDLogError(@"Routing operation failed to retreive default parameters: %@", [error localizedDescription]);
        self.routingOperation = nil;
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult
{
    if (op == self.routingOperation)
    {
        [self.routingAnnotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MGSMapAnnotation class]])
            {
                MGSMapAnnotation *annotation = (MGSMapAnnotation*)obj;
                AGSGraphic *graphic = [self.routingStops objectAtIndex:idx];
                annotation.agsGraphic = graphic;
            }
        }];
        
        self.annotations = self.routingAnnotations;
        DDLogVerbose(@"Routing operation complete!");
        self.routingStops = nil;
        self.routingAnnotations = nil;
        self.routingOperation = nil;
        
        [self refreshLayer];
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailSolveWithError:(NSError *)error
{
    if (op == self.routingOperation)
    {
        DDLogError(@"Routing operation failed with error [%@:%ld]: %@\n%@", error.domain, (long)error.code, [error localizedDescription], [error userInfo]);
        
        self.annotations = self.routingAnnotations;
        self.routingStops = nil;
        self.routingAnnotations = nil;
        self.routingOperation = nil;
        
        [self refreshLayer];
    }
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindAddressForLocation:(AGSAddressCandidate *)candidate
{
    NSInteger index = [self.locatorOperations indexOfObject:op];
    if (index == -1)
    {
        return;
    }
    
    if (self.locatedStops == nil)
    {
        self.locatedStops = [NSMutableDictionary dictionary];
    }
    
    [self.locatedStops setObject:candidate.location
                          forKey:[NSNumber numberWithInteger:index]];
    
    self.locatorCount -= 1;
    
    if (self.locatorCount == 0)
    {
        // Time to start routing!
        NSArray *sortedKeys = [[self.locatedStops allKeys] sortedArrayUsingSelector:@selector(compare:)];
        /*
        [sortedKeys enumerateObjectsUsingBlock:^(NSNumber *key, NSUInteger idx, BOOL *stop) {
            AGSPoint *point = [self.locatedStops objectForKey:key];
            MGSMapAnnotation *annotation = [self.annotations ]
            
        }];
        */
    }
    
    
    NSMutableArray *stops = [NSMutableArray array];
    
    AGSSpatialReference *reference = nil;
    
    if (self.graphicsView.mapView)
    {
        reference = self.graphicsView.mapView.spatialReference;
        reference = [AGSSpatialReference spatialReferenceWithWKID:2249];
    }
    else
    {
        reference = [AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84];
    }
    
    [self.annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MGSMapAnnotation class]])
        {
            MGSMapAnnotation *annotation = (MGSMapAnnotation*)obj;
            AGSGraphic *graphic = [MGSMapAnnotation graphicOfType:MGSGraphicStop
                                                   withAnnotation:annotation
                                                         template:self.markerTemplate];
            
            if (reference && ([graphic.geometry.spatialReference isEqualToSpatialReference:reference] == NO))
            {
                graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                           toSpatialReference:reference];
            }
            
            annotation.agsGraphic = nil;
            [stops addObject:graphic];
        }
    }];
    
    AGSRouteTaskParameters *routeParams = self.routingParameters;
    routeParams.preserveFirstStop = NO;
    routeParams.preserveLastStop = NO;
    routeParams.returnDirections = YES;
    routeParams.returnRouteGraphics = YES;
    routeParams.returnStopGraphics = YES;
    [routeParams setStopsWithFeatures:stops];
    
    self.routingAnnotations = self.annotations;
    self.annotations = nil;
    self.routingStops = stops;
    
    self.routingOperation = [self.routingTask solveWithParameters:routeParams];
}
@end
