#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"
#import "MGSUtility.h"
#import "MGSAnnotation.h"
#import "MGSLayer.h"
#import "MGSLayer+Protected.h"
#import "MGSLayerAnnotation.h"
#import "MGSCalloutView.h"

#import "MITLoadingActivityView.h"
#import "MITMobileServerConfiguration.h"
#import "MobileRequestOperation.h"

static NSString* const kMGSMapDefaultLayerIdentifier = @"edu.mit.mobile.map.Default";

@interface MGSMapView () <AGSMapViewTouchDelegate,AGSMapViewLayerDelegate>
@property (nonatomic, strong) NSOperationQueue *operationQueue;

#pragma mark - Basemap Management (Declaration)
@property (nonatomic, assign) BOOL coreLayersLoaded;
@property (nonatomic, strong) NSArray *coreMapIdentifiers;
@property (nonatomic, strong) NSDictionary *coreMapSets;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property (nonatomic, strong) NSMutableDictionary *userLayers;
@property (nonatomic, strong) NSMutableArray *userLayerOrder;
@property (nonatomic, strong) NSMutableArray *pendingLayers;
#pragma mark -

@property (strong) NSMutableDictionary *queryTasks;
@property (nonatomic, assign) AGSMapView *mapView;
@property (nonatomic, assign) MITLoadingActivityView *loadingView;
@property (nonatomic, strong) MGSLayer *defaultLayer;

- (void)initView;
- (AGSLayer*)arcgisLayerWithIdentifier:(NSString*)identifier;
- (UIView<AGSLayerView>*)arcgisViewWithIdentifier:(NSString*)identifier;
@end

@implementation MGSMapView

@dynamic mapSets;
@dynamic allLayers;
@dynamic visibleLayers;
@dynamic showUserLocation;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.queryTasks = [NSMutableDictionary dictionary];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    self.pendingLayers = [NSMutableArray array];
    
    self.coreLayersLoaded = NO;
    
    self.userLayers = [NSMutableDictionary dictionary];
    self.userLayerOrder = [NSMutableArray array];
    
    [self initView];
}

- (void)initView
{
    if (self.mapView == nil)
    {
        self.backgroundColor = [UIColor lightGrayColor];
        CGRect mainBounds = self.bounds;
        
        {
            AGSMapView* view = [[AGSMapView alloc] initWithFrame:mainBounds];
            view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
            view.touchDelegate = self;
            view.layerDelegate = self;
            view.hidden = YES;
            
            [self addSubview:view];
            self.mapView = view;
        }
        
        {
            MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:mainBounds];
            loadingView.backgroundColor = [UIColor clearColor];
            loadingView.usesBackgroundImage = NO;
            
            self.loadingView = loadingView;
            [self insertSubview:loadingView
                   aboveSubview:self.mapView];
        }
        
        
        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"map"
                                                                                command:@"bootstrap"
                                                                             parameters:nil];
        [operation setCompleteBlock:^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
            if (error)
            {
                DDLogError(@"failed to load basemap definitions: %@", error);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Map Error"
                                                                    message:@"Failed to initialize the map."
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            else if ([content isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *response = (NSDictionary*)content;
                self.coreMapSets = response[@"basemaps"];
                
                NSString *defaultSetName = response[@"defaultBasemap"];
                
                if ([defaultSetName length] == 0)
                {
                    defaultSetName = [[self.coreMapSets allKeys] objectAtIndex:0];
                }
                
                self.activeMapSet = defaultSetName;
            }
        }];
        
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
}

#pragma mark - Basemap Management
- (NSSet*)mapSets
{
    return [NSSet setWithArray:[self.coreMapSets allKeys]];
}

- (NSString*)nameForMapSetWithIdentifier:(NSString *)mapSetIdentifier
{
    NSDictionary *layerInfo = self.coreMapSets[mapSetIdentifier];
    return layerInfo[@"displayName"];
}

- (void)setActiveMapSet:(NSString *)mapSetName
{
    if (self.coreMapSets[mapSetName])
    {
        BOOL replaceLayers = ([self.coreMapIdentifiers count] > 0);
        NSMutableArray *layerIdentifiers = [NSMutableArray array];
        NSMutableArray *arcgisLayers = [NSMutableArray array];
        
        for (NSDictionary *layerInfo in self.coreMapSets[mapSetName])
        {
            NSString *displayName = layerInfo[@"displayName"];
            NSString *identifier = layerInfo[@"layerIdentifier"];
            NSURL *layerURL = [NSURL URLWithString:layerInfo[@"url"]];
            
            DDLogVerbose(@"adding layer '%@' [%@]",displayName,identifier);
            
            AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            
            [layerIdentifiers addObject:identifier];
            [arcgisLayers addObject:serviceLayer];
        }
        
        if (replaceLayers)
        {
            [self.coreMapIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
                [self.mapView removeMapLayerWithName:identifier];
            }];
            
            [layerIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
                AGSLayer *layer = arcgisLayers[idx];
                
                [self.mapView insertMapLayer:layer
                                    withName:identifier
                                     atIndex:idx];
            }];
        }
        else
        {
            [layerIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
                AGSLayer *layer = arcgisLayers[idx];
                
                [self.mapView addMapLayer:layer
                                 withName:identifier];
            }];
        }
        
        self.coreMapIdentifiers = layerIdentifiers;
        _activeMapSet = mapSetName;
    }
}

- (AGSLayer*)arcgisLayerWithIdentifier:(NSString*)identifier
{
    __block AGSLayer* layer = nil;
    
    [self.mapView.mapLayers enumerateObjectsUsingBlock:^(AGSLayer *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.name isEqualToString:identifier])
        {
            layer = obj;
            (*stop) = YES;
        }
    }];
    
    return layer;
}

- (UIView<AGSLayerView>*)arcgisViewWithIdentifier:(NSString*)identifier
{
    return (UIView<AGSLayerView>*)(self.mapView.mapLayerViews[identifier]);
}

- (MGSLayer*)defaultLayer
{
    if (_defaultLayer == nil)
    {
      self.defaultLayer = [[MGSLayer alloc] initWithName:@"Default"];
      [self addLayer:_defaultLayer
      withIdentifier:kMGSMapDefaultLayerIdentifier];
    }
    
    return _defaultLayer;
}
#pragma mark -

#pragma mark - Dynamic Properties
- (void)setCoreLayersLoaded:(BOOL)coreLayersLoaded
{
    if (_coreLayersLoaded != coreLayersLoaded)
    {
        _coreLayersLoaded = coreLayersLoaded;
        
        if (_coreLayersLoaded)
        {
            for (NSDictionary *dict in self.pendingLayers)
            {
                NSString *identifier = dict[@"identifier"];
                MGSLayer *layer = dict[@"layer"];
                NSUInteger index = [dict[@"index"] unsignedIntegerValue];
                
                [self insertLayer:layer
                          atIndex:index
                   withIdentifier:identifier];
            }
            
            [self.pendingLayers removeAllObjects];
        }
    }
}

- (void)setShowUserLocation:(BOOL)showUserLocation
{
    AGSGPS *gps = [self.mapView gps];
    if (showUserLocation && (gps.enabled == NO))
    {
        gps.autoPanMode = AGSGPSAutoPanModeOff;
        [gps start];
    }
    else if ((showUserLocation == NO) && gps.enabled)
    {
        [gps stop];
    }
}

- (BOOL)showUserLocation
{
    return [[self.mapView gps] enabled];
}

- (MKCoordinateRegion)mapRegion
{
    AGSPolygon *polygon = [self.mapView visibleArea];
    
    AGSPolygon *polygonWgs84 = (AGSPolygon*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polygon
                                                                       toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];

    
    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(polygonWgs84.envelope.center.y, polygonWgs84.envelope.center.x),
                                  MKCoordinateSpanMake(polygonWgs84.envelope.height, polygonWgs84.envelope.height));
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion
{
    double offsetX = (mapRegion.span.longitudeDelta / 2.0);
    double offsetY = (mapRegion.span.latitudeDelta / 2.0);
    AGSSpatialReference *wgs84 = [AGSSpatialReference wgs84SpatialReference];
    
    NSMutableArray *agsPoints = [NSMutableArray arrayWithCapacity:4];
    
    [agsPoints addObject:[AGSPoint pointWithX:(mapRegion.center.longitude + offsetX)
                                            y:(mapRegion.center.latitude + offsetY)
                             spatialReference:wgs84]];
    
    [agsPoints addObject:[AGSPoint pointWithX:(mapRegion.center.longitude + offsetX)
                                            y:(mapRegion.center.latitude - offsetY)
                             spatialReference:wgs84]];
    
    [agsPoints addObject:[AGSPoint pointWithX:(mapRegion.center.longitude - offsetX)
                                            y:(mapRegion.center.latitude + offsetY)
                             spatialReference:wgs84]];
    
    [agsPoints addObject:[AGSPoint pointWithX:(mapRegion.center.longitude - offsetX)
                                            y:(mapRegion.center.latitude - offsetY)
                             spatialReference:wgs84]];
    
    AGSMutablePolygon *visibleArea = [[AGSMutablePolygon alloc] init];
    visibleArea.spatialReference = wgs84;
    [visibleArea addRingToPolygon];
    
    for (AGSPoint *point in agsPoints)
    {
        [visibleArea addPointToRing:point];
    }
    
    [visibleArea closePolygon];
    
    AGSPolygon *projectedPolygon = (AGSPolygon*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:visibleArea
                                                                                        toSpatialReference:self.mapView.spatialReference];
    [self.mapView zoomToGeometry:projectedPolygon
                     withPadding:20
                        animated:YES];
}

#pragma mark - Layer Management
- (void)addLayer:(MGSLayer*)layer
  withIdentifier:(NSString*)layerIdentifier
{
    [self insertLayer:layer
              atIndex:[self.userLayers count]
       withIdentifier:layerIdentifier];
}

- (void)insertLayer:(MGSLayer*)layer
            atIndex:(NSUInteger)layerIndex
     withIdentifier:(NSString*)layerIdentifier
{
    if (self.coreLayersLoaded)
    {
        if (self.userLayers[layerIdentifier])
        {
            DDLogError(@"layer identifier collision for '%@'", layerIdentifier);
        }
        else
        {
            NSUInteger index = [self.coreMapIdentifiers count] + layerIndex;
            DDLogVerbose(@"adding layer '%@' at index %d (%d)", layerIdentifier, layerIndex, index);
            
            [self willAddLayer:layer];
            
            AGSGraphicsLayer *agsLayer = [layer graphicsLayer];
            layer.graphicsView = [self.mapView insertMapLayer:agsLayer
                                                     withName:layerIdentifier
                                                      atIndex:index];
            layer.graphicsView.drawDuringPanning = YES;
            layer.graphicsView.drawDuringZooming = YES;
            
            layer.mapView = self;
            
            self.userLayers[layerIdentifier] = layer;
            [self.userLayerOrder insertObject:layer
                                      atIndex:layerIndex];
            
            if ([layerIdentifier isEqualToString:kMGSMapDefaultLayerIdentifier] == NO)
            {
                [self moveLayerToTop:kMGSMapDefaultLayerIdentifier];
            }
            
            [self didAddLayer:layer];
        }
    }
    else
    {
        [self.pendingLayers addObject:@{@"identifier" : layerIdentifier,
                                        @"layer" : layer,
                                        @"index" : [NSNumber numberWithUnsignedInteger:layerIndex + [self.pendingLayers count]]}];
    }
}

- (void)moveLayerToTop:(NSString*)layerIdentifier
{
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];
    
    if (layer)
    {
        AGSGraphicsLayer *agsLayer = layer.graphicsLayer;
        
        [self.mapView removeMapLayerWithName:layerIdentifier];
        [self.userLayerOrder removeObject:layer];
        
        layer.graphicsView = [self.mapView addMapLayer:agsLayer
                                              withName:layerIdentifier];
        [self.userLayerOrder addObject:layer];
    }
}

- (MGSLayer*)layerWithIdentifier:(NSString*)layerIdentifier
{
    return self.userLayers[layerIdentifier];
}

- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier
{
    return ([self layerWithIdentifier:layerIdentifier] != nil);
}

- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier
{
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];
    
    if (layer)
    {
        [self willRemoveLayer:layer];
        
        AGSLayer *graphicsLayer = layer.graphicsLayer;
        [self.mapView removeMapLayerWithName:graphicsLayer.name];
        
        layer.graphicsView = nil;
        layer.graphicsLayer = nil;
        layer.mapView = nil;
        
        [self didRemoveLayer:layer];
    }
}

- (BOOL)isLayerHidden:(NSString*)layerIdentifier
{
    UIView<AGSLayerView> *view = [[self.mapView mapLayerViews] objectForKey:layerIdentifier];
    return view.hidden;
}

- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString*)layerIdentifier
{
    UIView<AGSLayerView> *view = [[self.mapView mapLayerViews] objectForKey:layerIdentifier];
    view.hidden = hidden;
}

- (void)centerOnAnnotation:(id<MGSAnnotation>)annotation
{
    for (MGSLayer *layer in [self.userLayers allValues])
    {
        if ([layer.annotations containsObject:annotation])
        {
            [self centerAtCoordinate:annotation.coordinate];
            return;
        }
    }
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self centerAtCoordinate:coordinate
                    animated:NO];
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated
{
    [self.mapView centerAtPoint:AGSPointFromCLLocationCoordinate(coordinate)
                       animated:animated];
}


- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    return [self.mapView toScreenPoint:AGSPointFromCLLocationCoordinate(coordinate)];
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    for (MGSLayer *layer in [self.userLayers allValues])
    {
        if ([layer.annotations containsObject:annotation])
        {
            [self centerAtCoordinate:annotation.coordinate];
        }
    }
    
    self.mapView.callout.title = annotation.title;
    self.mapView.callout.detail = annotation.detail;
    
    if ([annotation respondsToSelector:@selector(image)])
    {
        self.mapView.callout.image = annotation.image;
    }
    else
    {
        self.mapView.callout.image = nil;
    }
    
    self.mapView.callout.leaderPositionFlags = AGSCalloutLeaderPositionAny;
    
    [self.mapView showCalloutAtPoint:AGSPointFromCLLocationCoordinate(annotation.coordinate)];
}

- (void)showCalloutWithView:(UIView*)view
              forAnnotation:(id<MGSAnnotation>)annotation
{
    self.mapView.callout.customView = view;
    [self showCalloutForAnnotation:annotation];
}

- (void)hideCallout
{
    self.mapView.callout.hidden = YES;
}


#pragma mark - AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *)mapView
{
    DDLogVerbose(@"Basemap loaded with WKID %d", mapView.spatialReference.wkid);
    
    AGSEnvelope *maxEnvelope = [AGSEnvelope envelopeWithXmin:-7915909.671294
                                                        ymin:5212249.807534
                                                        xmax:-7912606.241692
                                                        ymax:5216998.487588
                                            spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
    AGSEnvelope *projectedEnvelope = (AGSEnvelope*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:maxEnvelope
                                                                                            toSpatialReference:mapView.spatialReference];
    [mapView setMaxEnvelope:projectedEnvelope];
    [mapView zoomToEnvelope:projectedEnvelope
                   animated:YES];

    [UIView transitionFromView:self.loadingView
                        toView:self.mapView
                      duration:0.5
                       options:(UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionCrossDissolve)
                    completion:^(BOOL finished) {
                        if (finished)
                        {
                            [self didFinishLoadingMapView];
                        }
                    }];
}

- (void)mapView:(AGSMapView *)mapView failedLoadingLayerForLayerView:(UIView<AGSLayerView> *)layerView baseLayer:(BOOL)baseLayer withError:(NSError *)error
{
    
    NSString *identifier = layerView.agsLayer.name;
    
    if ([self.coreMapIdentifiers containsObject:identifier])
    {
        BOOL coreLayersLoaded = YES;
        for (NSString *identifier in self.coreMapIdentifiers)
        {
            UIView<AGSLayerView> *layerView = mapView.mapLayerViews[identifier];
            coreLayersLoaded = coreLayersLoaded && (layerView.agsLayer.isLoaded || layerView.agsLayer.error);
        }
        
        if (coreLayersLoaded)
        {
            self.coreLayersLoaded = YES;
            [self didFinishLoadingMapView];
        }
        
        DDLogError(@"Layer '%@' [%d,%p] failed to load: %@", layerView.agsLayer.name, layerView.agsLayer.isLoaded, layerView.agsLayer.error, [error localizedDescription]);
    }
}

- (void)mapView:(AGSMapView *)mapView didLoadLayerForLayerView:(UIView<AGSLayerView> *)layerView
{
    
    NSString *identifier = layerView.agsLayer.name;
    
    if ([self.coreMapIdentifiers containsObject:identifier])
    {
        BOOL coreLayersLoaded = YES;
        for (NSString *identifier in self.coreMapIdentifiers)
        {
            UIView<AGSLayerView> *layerView = mapView.mapLayerViews[identifier];
            coreLayersLoaded = coreLayersLoaded && (layerView.agsLayer.isLoaded || layerView.agsLayer.error);
        }
        
        if (coreLayersLoaded)
        {
            self.coreLayersLoaded = YES;
            [self didFinishLoadingMapView];
        }
        
        DDLogVerbose(@"Successfully loaded core layer '%@'", identifier);
    }
    else
    {
        MGSLayer *layer = [self layerWithIdentifier:identifier];
        layer.graphicsView = layerView;
        DDLogVerbose(@"Successfully loaded layer %@", identifier);
    }
}

#pragma mark - AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics
{
    DDLogVerbose(@"Got a tap, found %d graphics", [graphics count]);
}


#pragma mark - MGSMapView Delegate Forwarding
- (void)didFinishLoadingMapView
{
    if ([self.mapViewDelegate respondsToSelector:@selector(didFinishLoadingMapView:)])
    {
        [self.mapViewDelegate didFinishLoadingMapView:self];
    }
}

- (void)willShowCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willShowCalloutForAnnotation:)])
    {
        [self.mapViewDelegate mapView:self
         willShowCalloutForAnnotation:annotation];
    }
}

- (void)didShowCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didShowCalloutForAnnotation:)])
    {
        [self.mapViewDelegate mapView:self
          didShowCalloutForAnnotation:annotation];
    }
}

- (void)calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:calloutAccessoryDidReceiveTapForAnnotation:)])
    {
        [self.mapViewDelegate mapView:self
calloutAccessoryDidReceiveTapForAnnotation:annotation];
    }
}

- (void)willAddLayer:(MGSLayer*)layer
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willAddLayer:)])
    {
        [self.mapViewDelegate mapView:self
                         willAddLayer:layer];
    }
}

- (void)didAddLayer:(MGSLayer*)layer
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didAddLayer:)])
    {
        [self.mapViewDelegate mapView:self
                          didAddLayer:layer];
    }
}

- (void)willRemoveLayer:(MGSLayer*)layer
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willRemoveLayer:)])
    {
        [self.mapViewDelegate mapView:self
                      willRemoveLayer:layer];
    }
}

- (void)didRemoveLayer:(MGSLayer*)layer
{
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didRemoveLayer:)])
    {
        [self.mapViewDelegate mapView:self
                       didRemoveLayer:layer];
    }
}
@end
