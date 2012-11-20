

#import "MGSMapView.h"

#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate.h"
#import "MGSMapLayer.h"

#import "MITLoadingActivityView.h"
#import "MITMobileServerConfiguration.h"

#import <ArcGIS/ArcGIS.h>
#import "MGSMapAnnotation+AGS.h"
#import "MGSMapCoordinate+AGS.h"
#import "MGSMapLayer+AGS.h"
#import "MobileRequestOperation.h"

static NSString* const kMGSMapDefaultLayerIdentifier = @"edu.mit.mobile.map.Default";

@interface MGSMapView () <AGSMapViewTouchDelegate,AGSMapViewLayerDelegate>
@property (nonatomic, strong) NSOperationQueue *operationQueue;

#pragma mark - Basemap Management (Declaration)
// Only contains layers identified as capable of being the
// basemap.
@property (nonatomic, strong) NSDictionary *coreLayers;
@property (nonatomic, strong) NSDictionary *coreLayerSets;

@property (nonatomic, strong) NSString *activeBasemapSet;

@property (nonatomic, strong) NSMutableSet *allBasemaps;

// Contains all identifiers for the default layers
@property (nonatomic, strong) NSMutableSet *basemapIdentifiers;
@property (nonatomic, strong) NSSet *initialLayerInfo;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property (nonatomic, strong) NSMutableArray *mgsLayerIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *mgsLayers;
@property (nonatomic, strong) NSMutableDictionary *mgsNotificationObjects;
@property (nonatomic, assign) NSUInteger indexOffset;
#pragma mark -

@property (strong) NSMutableDictionary *queryTasks;
@property (nonatomic, assign) AGSMapView *mapView;
@property (nonatomic, assign) MITLoadingActivityView *loadingView;
@property (nonatomic, strong) MGSMapLayer *defaultLayer;

- (void)initView;
- (void)initBaseLayersWithDictionary:(NSDictionary*)bootstrapDictionary;
@end

@implementation MGSMapView

@dynamic availableBasemaps;
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
    self.allBasemaps = [NSMutableSet set];
    self.basemapIdentifiers = [NSMutableSet set];
    self.coreLayers = [NSMutableDictionary dictionary];
    self.indexOffset = 0;
    self.mgsNotificationObjects = [NSMutableDictionary dictionary];
    self.mgsLayers = [NSMutableDictionary dictionary];
    self.mgsLayerIdentifiers = [NSMutableArray array];
    self.queryTasks = [NSMutableDictionary dictionary];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
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
                [self initBaseLayersWithDictionary:content];
            }
        }];
    }
}

#pragma mark - Basemap Management
- (void)initBaseLayersWithDictionary:(NSDictionary*)bootstrapDictionary
{
    NSString *defaultBasemap = bootstrapDictionary[@"defaultBasemap"];
    self.coreLayerSets = bootstrapDictionary[@"basemaps"];
    
    NSMutableDictionary *coreLayers = [NSMutableDictionary dictionary];

    if ([defaultBasemap length] == 0)
    {
        DDLogError(@"no default layer set defined, behavior will be undefined");
        defaultBasemap = [[NSSet setWithArray:[self.coreLayerSets allKeys]] anyObject];
    }
    
    for (NSArray *layers in self.coreLayerSets[defaultBasemap])
    {
        for (NSDictionary *layerInfo in layers)
        {
            NSString *displayName = layerInfo[@"displayName"];
            NSString *identifier = layerInfo[@"layerIdentifier"];
            NSURL *layerURL = [NSURL URLWithString:layerInfo[@"url"]];
            BOOL isEnabled = [layerInfo[@"isEnabled"] boolValue];
            
            if (isEnabled == NO)
            {
                continue;
            }
            else if (coreLayers[identifier] != nil)
            {
                DDLogError(@"identifier collision for layer '%@ [%@]'",displayName,identifier);
                continue;
            }
            
            AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            coreLayers[identifier] = serviceLayer;
            
            [self.mapView addMapLayer:serviceLayer
                             withName:identifier];
        }
    }
    
    self.coreLayers = coreLayers;
}

- (void)initDisplayLayers:(NSArray*)layers
{
    NSMutableDictionary *agsLayers = [NSMutableDictionary dictionaryWithDictionary:self.coreLayers];
    self.coreLayers = agsLayers;
    
    [layers enumerateObjectsUsingBlock:^(NSDictionary *layerInfo, NSUInteger idx, BOOL *stop) {
        NSURL *layerURL = [NSURL URLWithString:[layerInfo valueForKey:@"url"]];
        NSString *layerIdentifier = [layerInfo objectForKey:@"layerIdentifier"];
        NSString *layerName = [layerInfo objectForKey:@"displayName"];
        
        BOOL isFeatureLayer = [[layerInfo objectForKey:@"isFeatureLayer"] boolValue];
        BOOL isDataOnly = [[layerInfo objectForKey:@"isDataOnly"] boolValue];
        
        if (isFeatureLayer)
        {
            AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:layerURL
                                                                                   mode:AGSFeatureLayerModeOnDemand];
            
            if (isDataOnly)
            {
                AGSSimpleFillSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:[UIColor clearColor]
                                                                                outlineColor:[UIColor clearColor]];
                
                AGSRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:symbol];
                featureLayer.renderer = renderer;
            }
            
            [agsLayers setObject:featureLayer
                          forKey:layerIdentifier];
            [self.mapView insertMapLayer:featureLayer
                                withName:layerIdentifier
                                 atIndex:self.indexOffset];
            DDLogVerbose(@"Adding feature layer '%@' [%@] at index %d", layerIdentifier, layerName, self.indexOffset);
            self.indexOffset += 1;
        }
        else
        {
            AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            [agsLayers setObject:serviceLayer
                          forKey:layerIdentifier];
            
            [self.mapView insertMapLayer:serviceLayer
                                withName:layerIdentifier
                                 atIndex:self.indexOffset];
            DDLogVerbose(@"Adding service layer '%@' [%@] at index %d", layerIdentifier, layerName, self.indexOffset);
            self.indexOffset += 1;
        }
    }];
}

- (NSSet*)availableBasemapLayers
{
    return self.basemapIdentifiers;
}

- (NSString*)basemapLayerIdentifier
{
    return [[[self.mapView mapLayers] objectAtIndex:0] name];
}

- (void)setActiveBasemap:(NSString *)activeBasemap
{
    if ([self.activeBasemap isEqualToString:activeBasemap] == NO)
    {
        if ([self.basemapIdentifiers containsObject:activeBasemap])
        {
            AGSLayer *layer = [self.coreLayers objectForKey:activeBasemap];
            [self.mapView insertMapLayer:layer
                                withName:activeBasemap
                                 atIndex:0];
            
            if ([self.activeBasemap length] > 0)
            {
                [self.mapView removeMapLayerWithName:self.activeBasemap];
            }
            
            _activeBasemap = activeBasemap;
        }
    }
}


- (NSString*)nameForBasemapWithIdentifier:(NSString*)basemapIdentifier
{
    __block NSString *layerName = nil;
    
    if ([self.basemapIdentifiers containsObject:basemapIdentifier])
    {
        [self.initialLayerInfo enumerateObjectsUsingBlock:^(NSDictionary *layerInfo, BOOL *stop) {
            NSString *layerIdentifier = [layerInfo objectForKey:@"layerIdentifier"];
            
            if ([basemapIdentifier isEqualToString:layerIdentifier])
            {
                layerName = [layerInfo objectForKey:@"displayName"];
                (*stop) = YES;
            }
        }];
    }
    
    return layerName;
}

- (MGSMapLayer*)defaultLayer
{
    if (_defaultLayer == nil)
    {
      self.defaultLayer = [[MGSMapLayer alloc] initWithName:@"Default"];
      [self addLayer:_defaultLayer
      withIdentifier:kMGSMapDefaultLayerIdentifier];
    }
    
    return _defaultLayer;
}
#pragma mark -

#pragma mark - Dynamic Properties
- (void)setShowUserLocation:(BOOL)showUserLocation
{
    AGSGPS *gps = [self.mapView gps];
    if (showUserLocation && (gps.enabled == NO))
    {
        gps.autoPanMode = AGSGPSAutoPanModeDefault;
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
    AGSSpatialReference *wgs84 = [AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84];
    
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
    [visibleArea addRingToPolygon];
    
    for (AGSPoint *point in agsPoints)
    {
        [visibleArea addPointToRing:point];
    }
    
    [visibleArea closePolygon];
    [self.mapView zoomToGeometry:visibleArea
                     withPadding:0
                        animated:YES];
}

#pragma mark - Layer Management
- (BOOL)addLayer:(MGSMapLayer*)layer
  withIdentifier:(NSString*)layerIdentifier
{
    if ([self layerWithIdentifier:layerIdentifier])
    {
        DDLogError(@"Layer already exists for identifier '%@'", layerIdentifier);
        return NO;
    }
    
    AGSGraphicsLayer *agsLayer = [layer graphicsLayer];
    
    DDLogVerbose(@"Adding layer '%@' at index %d", layerIdentifier, [self.mapView.mapLayers count]);
    
    [self.mgsLayerIdentifiers addObject:layerIdentifier];
    [self.mgsLayers setObject:layer
                       forKey:layerIdentifier];
    
    layer.graphicsView = [self.mapView addMapLayer:agsLayer
                                          withName:layerIdentifier];
    
    if ([layerIdentifier isEqualToString:kMGSMapDefaultLayerIdentifier] == NO)
    {
        [self moveLayerToTop:kMGSMapDefaultLayerIdentifier];
    }
    
    layer.mapView = self;
    
    return YES;
}

- (BOOL)insertLayer:(MGSMapLayer*)layer
            atIndex:(NSUInteger)layerIndex
     withIdentifier:(NSString*)layerIdentifier
{
    if ([self layerWithIdentifier:layerIdentifier])
    {
        DDLogError(@"Layer already exists for identifier '%@'", layerIdentifier);
        return NO;
    }
    
    AGSGraphicsLayer *agsLayer = [layer graphicsLayer];
    
    NSUInteger index = self.indexOffset + layerIndex;
    DDLogVerbose(@"Adding layer '%@' at index %d", layerIdentifier, index);
    
    [self.mgsLayerIdentifiers insertObject:layerIdentifier
                                   atIndex:layerIndex];
    [self.mgsLayers setObject:layer
                       forKey:layerIdentifier];
    
    layer.graphicsView = [self.mapView insertMapLayer:agsLayer
                                             withName:layerIdentifier
                                              atIndex:index];
    
    if ([layerIdentifier isEqualToString:kMGSMapDefaultLayerIdentifier] == NO)
    {
        [self moveLayerToTop:kMGSMapDefaultLayerIdentifier];
    }
    
    layer.mapView = self;
    
    return YES;
}

- (void)moveLayerToTop:(NSString*)layerIdentifier
{
    MGSMapLayer *layer = [self layerWithIdentifier:layerIdentifier];
    
    if (layer)
    {
        [self removeLayerWithIdentifier:layerIdentifier];
        [self addLayer:layer
        withIdentifier:layerIdentifier];
    }
}

- (MGSMapLayer*)layerWithIdentifier:(NSString*)layerIdentifier
{
    return [self.mgsLayers objectForKey:layerIdentifier];
}

- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier
{
    return ([self layerWithIdentifier:layerIdentifier] != nil);
}

- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier
{
    MGSMapLayer *layer = [self layerWithIdentifier:layerIdentifier];
    
    if (layer)
    {
        [self.mgsLayers removeObjectForKey:layerIdentifier];
        [self.mapView removeMapLayerWithName:layerIdentifier];
        [self.mgsLayerIdentifiers removeObject:layerIdentifier];
        layer.mapView = nil;
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

- (void)centerOnAnnotation:(MGSMapAnnotation *)annotation
{
    if (annotation.agsGraphic)
    {
        [self.mapView centerAtPoint:annotation.agsGraphic.geometry.envelope.center
                           animated:YES];
    }
}

- (void)centerAtCoordinate:(MGSMapCoordinate *)coordinate
{
    [self centerAtCoordinate:coordinate
                    animated:NO];
}

- (void)centerAtCoordinate:(MGSMapCoordinate *)coordinate animated:(BOOL)animated
{
    [self.mapView centerAtPoint:coordinate.agsPoint
                       animated:animated];
}


- (CGPoint)screenPointForCoordinate:(MGSMapCoordinate*)coordinate
{
    return [self.mapView toScreenPoint:[coordinate agsPoint]];
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(MGSMapAnnotation*)annotation
{
    self.mapView.callout.title = annotation.title;
    self.mapView.callout.detail = annotation.detail;
    self.mapView.callout.image = annotation.image;
    self.mapView.callout.leaderPositionFlags = AGSCalloutLeaderPositionAny;
    [self.mapView showCalloutAtPoint:[[annotation coordinate] agsPoint]
                          forGraphic:annotation.agsGraphic
                            animated:YES];
}

- (void)showCalloutWithView:(UIView*)view
              forAnnotation:(MGSMapAnnotation*)annotation
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
    
    NSSet *display = [self.initialLayerInfo filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"(self.isBasemap == nil) || (self.isBasemap == NO)"]];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                [NSSortDescriptor sortDescriptorWithKey:@"isEnabled" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"isBasemap" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"layerIndex" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"isFeatureLayer" ascending:NO],
                                nil];
    [self initDisplayLayers:[display sortedArrayUsingDescriptors:sortDescriptors]];

    [UIView transitionFromView:self.loadingView
                        toView:self.mapView
                      duration:0.5
                       options:(UIViewAnimationOptionShowHideTransitionViews |
                                UIViewAnimationOptionTransitionCrossDissolve)
                    completion:^(BOOL finished) {
                        if (finished)
                        {
                            if (self.mapViewDelegate)
                            {
                                [self.mapViewDelegate didFinishLoadingMapView:self];
                            }
                            
                        }
                    }];
}

- (void)mapView:(AGSMapView *)mapView didLoadLayerForLayerView:(UIView<AGSLayerView> *)layerView
{
    NSString *identifier = layerView.agsLayer.name;
    MGSMapLayer *layer = [self layerWithIdentifier:identifier];
    layer.graphicsView = layerView;
    DDLogVerbose(@"Successfully loaded layer %@", identifier);
}

- (void)mapView:(AGSMapView *)mapView failedLoadingLayerForLayerView:(UIView<AGSLayerView> *)layerView withError:(NSError *)error
{
    DDLogError(@"Layer '%@' failed to load: %@", layerView.agsLayer.name, [error localizedDescription]);
}

#pragma mark - AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics
{
    DDLogVerbose(@"Got a tap, found %d graphics", [graphics count]);
    DDLogVerbose(@"\tDict:\n----\n%@\n----", graphics);
    
    NSMutableDictionary *mgsAnnotations = [NSMutableDictionary dictionary];
    
    [graphics enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, NSArray *graphics, BOOL *stop) {
        if ([graphics count])
        {
            NSMutableArray *layerAnnotations = [NSMutableArray array];
            for (AGSGraphic *graphic in graphics)
            {
                MGSMapAnnotation *mapAnnotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
                if (mapAnnotation)
                {
                    [layerAnnotations addObject:mapAnnotation];
                }
            }
            
            [mgsAnnotations setObject:layerAnnotations
                               forKey:identifier];
        }
    }];
    
    __block BOOL graphicFound = NO;
    
    [self.mgsLayerIdentifiers enumerateObjectsWithOptions:NSEnumerationReverse
                                               usingBlock: ^(NSString *layer, NSUInteger idx, BOOL *stop) {
                                                   NSArray *objects = [graphics objectForKey:layer];
                                                   
                                                   if ([objects count])
                                                   {
                                                       AGSGraphic *graphic = [objects objectAtIndex:0];
                                                       [self.mapView showCalloutAtPoint:nil
                                                                             forGraphic:graphic
                                                                               animated:YES];
                                                       graphicFound = YES;
                                                   }
                                               }];
    
    
    if (graphicFound)
        return;
    
    NSArray *geometryObjects = [graphics objectForKey:@"edu.mit.mobile.map.buildings"];
    
    [geometryObjects enumerateObjectsUsingBlock:^(AGSGraphic *graphic, NSUInteger idx, BOOL *stop) {
        
        if ([graphic.geometry.envelope containsPoint:mappoint])
        {
            AGSFeatureLayer *featureLayer = (AGSFeatureLayer*)[graphic layer];
            NSString *title = [graphic.attributes objectForKey:featureLayer.displayField];
            self.mapView.callout.title = title;
            self.mapView.callout.detail = nil;
            [self.mapView showCalloutAtPoint:graphic.geometry.envelope.center
                                  forGraphic:graphic
                                    animated:YES];
        }
    }];
}
@end
