#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"
#import "MGSUtility.h"
#import "MGSLayer.h"
#import "MGSLayer+Subclass.h"
#import "MGSLayerAnnotation.h"
#import "MGSCalloutView.h"

#import "MobileRequestOperation.h"

static NSString *const kMGSMapDefaultLayerIdentifier = @"edu.mit.mobile.map.Default";

@interface MGSMapView () <AGSMapViewTouchDelegate, AGSMapViewLayerDelegate, AGSLayerDelegate>
@property(nonatomic, strong) NSOperationQueue *operationQueue;

#pragma mark - Basemap Management (Declaration)
@property(assign) BOOL coreLayersLoaded;
@property(strong) NSMutableDictionary *coreLayers;
@property(strong) NSDictionary *coreMaps;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property(strong) NSMutableDictionary *userLayers;
@property(strong) NSMutableArray *userLayerOrder;
@property (nonatomic, strong) NSOperationQueue *userLayerQueue;
#pragma mark -

@property(strong) NSMutableDictionary *queryTasks;
@property(nonatomic, assign) AGSMapView *mapView;
@property(strong) MGSLayer *defaultLayer;

- (void)initView;

- (AGSLayer *)arcgisLayerWithIdentifier:(NSString *)identifier;
@end

@implementation MGSMapView

@dynamic mapSets;
@dynamic allLayers;
@dynamic visibleLayers;
@dynamic showUserLocation;

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    self.queryTasks = [NSMutableDictionary dictionary];

    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;

    self.userLayerQueue = [[NSOperationQueue alloc] init];
    self.userLayerQueue.maxConcurrentOperationCount = 1;
    self.userLayerQueue.suspended = YES;

    self.coreLayersLoaded = NO;

    self.userLayers = [NSMutableDictionary dictionary];
    
    // Should be nil until all the core layers have been loaded
    self.userLayerOrder = nil;

    [self initView];
}

- (void)initView {
    if (self.mapView == nil) {
        self.backgroundColor = [UIColor lightGrayColor];
        CGRect mainBounds = self.bounds;

        {
            AGSMapView *view = [[AGSMapView alloc] initWithFrame:mainBounds];
            view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                    UIViewAutoresizingFlexibleHeight);
            view.touchDelegate = self;
            view.layerDelegate = self;

            [self addSubview:view];
            self.mapView = view;
        }


        MobileRequestOperation *operation = [MobileRequestOperation operationWithModule:@"map"
                                                                                command:@"bootstrap"
                                                                             parameters:nil];
        [operation setCompleteBlock:^(MobileRequestOperation *operation, id content, NSString *contentType, NSError *error) {
            if (error) {
                DDLogError(@"failed to load basemap definitions: %@", error);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Map Error"
                                                                    message:@"Failed to initialize the map."
                                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [alertView show];
            }
            else if ([content isKindOfClass:[NSDictionary class]]) {
                NSDictionary *response = (NSDictionary *) content;
                self.coreMaps = response[@"basemaps"];

                NSString *defaultSetName = response[@"defaultBasemap"];

                if ([defaultSetName length] == 0) {
                    defaultSetName = [[self.coreMaps allKeys] objectAtIndex:0];
                }

                self.activeMapSet = defaultSetName;
            }
        }];

        [[NSOperationQueue mainQueue] addOperation:operation];
    }
}

#pragma mark - Basemap Management
- (NSSet *)mapSets {
    return [NSSet setWithArray:[self.coreMaps allKeys]];
}

- (NSString *)nameForMapSetWithIdentifier:(NSString *)mapSetIdentifier {
    NSDictionary *layerInfo = self.coreMaps[mapSetIdentifier];
    return layerInfo[@"displayName"];
}

- (void)setActiveMapSet:(NSString *)mapSetName {
    if (self.coreMaps[mapSetName]) {
        NSMutableDictionary *coreMapLayers = [NSMutableDictionary dictionary];
        NSMutableArray *identifierOrder = [NSMutableArray array];

        for (NSDictionary *layerInfo in self.coreMaps[mapSetName]) {
            NSString *displayName = layerInfo[@"displayName"];
            NSString *identifier = layerInfo[@"layerIdentifier"];
            NSURL *layerURL = [NSURL URLWithString:layerInfo[@"url"]];

            DDLogVerbose(@"adding core layer '%@' [%@]", displayName, identifier);

            AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            serviceLayer.delegate = self;

            coreMapLayers[identifier] = serviceLayer;
            [identifierOrder addObject:identifier];
        }

        [self.coreLayers.allKeys enumerateObjectsUsingBlock:^(NSString *layerName, NSUInteger idx, BOOL *stop) {
            [self.mapView removeMapLayerWithName:layerName];
        }];

        [identifierOrder enumerateObjectsUsingBlock:^(NSString *layerName, NSUInteger idx, BOOL *stop) {
            [self.mapView insertMapLayer:coreMapLayers[layerName]
                                withName:layerName
                                 atIndex:idx];
        }];

        self.coreLayers = coreMapLayers;
        _activeMapSet = mapSetName;
    }
}

- (AGSLayer *)arcgisLayerWithIdentifier:(NSString *)identifier {
    __block AGSLayer *layer = nil;

    [self.mapView.mapLayers enumerateObjectsUsingBlock:^(AGSLayer *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.name isEqualToString:identifier]) {
            layer = obj;
            (*stop) = YES;
        }
    }];

    return layer;
}

- (MGSLayer *)defaultLayer {
    if (_defaultLayer == nil) {
        self.defaultLayer = [[MGSLayer alloc] initWithName:@"Default"];
        [self addLayer:_defaultLayer
        withIdentifier:kMGSMapDefaultLayerIdentifier];
    }

    return _defaultLayer;
}
#pragma mark -

#pragma mark - Dynamic Properties
- (void)setShowUserLocation:(BOOL)showUserLocation {
    if (self.mapView.locationDisplay.dataSource == nil) {
        self.mapView.locationDisplay.dataSource = [[AGSCLLocationManagerLocationDisplayDataSource alloc] init];
    }
    
    if (showUserLocation) {
        [self.mapView.locationDisplay.dataSource start];
        self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeOff;
    } else {
        [self.mapView.locationDisplay.dataSource stop];
    }

}

- (BOOL)showUserLocation {
    return self.mapView.locationDisplay.dataSource && self.mapView.locationDisplay.isDataSourceStarted;
}

- (MKCoordinateRegion)mapRegion {
    AGSPolygon *polygon = [self.mapView visibleArea];

    AGSPolygon *polygonWgs84 = (AGSPolygon *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polygon
                                                                                      toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];


    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(polygonWgs84.envelope.center.y, polygonWgs84.envelope.center.x),
                                  MKCoordinateSpanMake(polygonWgs84.envelope.height, polygonWgs84.envelope.height));
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion {
    double offsetX = (mapRegion.span.longitudeDelta / 2.0);
    double offsetY = (mapRegion.span.latitudeDelta / 2.0);
    AGSMutablePolygon *visibleArea = [[AGSMutablePolygon alloc] init];
    visibleArea.spatialReference = [AGSSpatialReference wgs84SpatialReference];
    [visibleArea addRingToPolygon];
    
    [visibleArea addPointToRing:[AGSPoint pointWithX:(mapRegion.center.longitude + offsetX)
                                                   y:(mapRegion.center.latitude + offsetY)
                                    spatialReference:nil]];
    
    [visibleArea addPointToRing:[AGSPoint pointWithX:(mapRegion.center.longitude + offsetX)
                                                   y:(mapRegion.center.latitude - offsetY)
                                    spatialReference:nil]];
    
    [visibleArea addPointToRing:[AGSPoint pointWithX:(mapRegion.center.longitude - offsetX)
                                                   y:(mapRegion.center.latitude + offsetY)
                                    spatialReference:nil]];
    
    [visibleArea addPointToRing:[AGSPoint pointWithX:(mapRegion.center.longitude - offsetX)
                                                   y:(mapRegion.center.latitude - offsetY)
                                    spatialReference:nil]];

    [visibleArea closePolygon];

    if (self.mapView.spatialReference) {
        AGSGeometry *geometry = visibleArea;
        AGSGeometry *projectedGeometry = visibleArea;
        
        if ([geometry.spatialReference isEqualToSpatialReference:self.mapView.spatialReference] == NO) {
            projectedGeometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:geometry
                                                                        toSpatialReference:self.mapView.spatialReference];
        }
        
        [self.mapView zoomToGeometry:projectedGeometry
                         withPadding:10.0 // Minimum of 20px padding on each side
                            animated:YES];
    }
}

#pragma mark - Layer Management
- (void)addLayer:(MGSLayer *)layer
  withIdentifier:(NSString *)layerIdentifier {
    [self insertLayer:layer
       withIdentifier:layerIdentifier
              atIndex:[self.userLayers count]];
}

- (void)insertLayer:(MGSLayer *)layer
     withIdentifier:(NSString *)layerIdentifier
        behindLayer:(MGSLayer *)foregroundLayer {
    
    // Delay this until the core layers are loaded as well since userLayerOrder
    // is not initialized yet and index will be set to NSNotFound (which is not
    // necessarily true)
    dispatch_block_t insertBlock = ^{
        NSUInteger index = [self.userLayerOrder indexOfObject:foregroundLayer];

        if (index == NSNotFound) {
            [self addLayer:layer
            withIdentifier:layerIdentifier];
        } else {
            [self insertLayer:layer
               withIdentifier:layerIdentifier
                      atIndex:index];
        }
    };
    
    self.userLayers[layerIdentifier] = [NSNull null];
    [self.userLayerQueue addOperationWithBlock:insertBlock];
}

- (void)insertLayer:(MGSLayer *)layer
     withIdentifier:(NSString *)layerIdentifier
            atIndex:(NSUInteger)layerIndex {

    NSString *identifier = [layerIdentifier copy];
    dispatch_block_t insertBlock = ^{
        MGSLayer *existingLayer = self.userLayers[identifier];
        
        if (self.userLayerOrder == nil) {
            self.userLayerOrder = [NSMutableArray array];
        }

        if ((existingLayer != nil) && ([existingLayer isEqual:[NSNull null]] == false)) {
            DDLogError(@"identifier collision for '%@'", identifier);
        } else {
            NSUInteger index = [self.coreLayers count] + layerIndex;
            DDLogVerbose(@"adding user layer '%@' at index %d (%d)", identifier, layerIndex, index);

            [self willAddLayer:layer];
            layer.mapView = self;

            self.userLayers[identifier] = layer;
            [self.userLayerOrder insertObject:layer
                                      atIndex:layerIndex];

            // Make sure we do this on the UI thread!
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mapView insertMapLayer:layer.graphicsLayer
                                    withName:layerIdentifier
                                     atIndex:index];
            });

            if ([identifier isEqualToString:kMGSMapDefaultLayerIdentifier] == NO) {
                [self moveLayerToTop:kMGSMapDefaultLayerIdentifier];
            }

            [self didAddLayer:layer];
        }
    };
    
    self.userLayers[layerIdentifier] = [NSNull null];
    [self.userLayerQueue addOperationWithBlock:insertBlock];
}

- (void)moveLayerToTop:(NSString *)layerIdentifier {
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];

    if (layer) {
        AGSGraphicsLayer *agsLayer = layer.graphicsLayer;

        [self.mapView removeMapLayerWithName:layerIdentifier];
        [self.userLayerOrder removeObject:layer];

        [self.mapView addMapLayer:agsLayer
                         withName:layerIdentifier];
        [self.userLayerOrder addObject:layer];
    }
}

- (MGSLayer *)layerWithIdentifier:(NSString *)layerIdentifier {
    return self.userLayers[layerIdentifier];
}

- (BOOL)containsLayerWithIdentifier:(NSString *)layerIdentifier {
    return ([self layerWithIdentifier:layerIdentifier] != nil);
}

- (void)removeLayerWithIdentifier:(NSString *)layerIdentifier {
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];

    if (layer) {
        [self willRemoveLayer:layer];

        AGSLayer *graphicsLayer = layer.graphicsLayer;
        [self.mapView removeMapLayerWithName:graphicsLayer.name];

        layer.graphicsLayer = nil;
        layer.mapView = nil;

        [self didRemoveLayer:layer];
    }
}

- (BOOL)isLayerHidden:(NSString *)layerIdentifier {
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];
    return layer.hidden;
}

- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString *)layerIdentifier {
    MGSLayer *layer = [self layerWithIdentifier:layerIdentifier];
    layer.hidden = hidden;
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [self centerAtCoordinate:coordinate
                    animated:NO];
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    [self.mapView centerAtPoint:AGSPointWithReferenceFromCLLocationCoordinate(coordinate, self.mapView.spatialReference)
                       animated:animated];
}


- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate {
    return [self.mapView toScreenPoint:AGSPointWithReferenceFromCLLocationCoordinate(coordinate, self.mapView.spatialReference)];
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    __block MGSLayerAnnotation *layerAnnotation = nil;

    [[self.userLayers allValues] enumerateObjectsUsingBlock:^(MGSLayer *layer, NSUInteger idx, BOOL *stop) {
        layerAnnotation = [layer layerAnnotationForAnnotation:annotation];
        (*stop) = (layerAnnotation != nil);
    }];

    if (layerAnnotation == nil) {
        return;
    }

    MGSCalloutView *callout = (MGSCalloutView *) self.mapView.callout.customView;
    if ((callout == nil) || ([callout isKindOfClass:[MGSCalloutView class]] == NO)) {
        callout = [[MGSCalloutView alloc] init];
        self.mapView.callout.customView = callout;
    }
    else {
        callout = (MGSCalloutView *) self.mapView.callout.customView;
    }

    callout.titleLabel.text = [annotation title];

    if ([annotation respondsToSelector:@selector(detail)]) {
        callout.detailLabel.text = [annotation detail];
    }

    if ([annotation respondsToSelector:@selector(calloutImage)]) {
        callout.imageView.image = [annotation calloutImage];
    }

    [callout sizeToFit];
    [callout setNeedsLayout];

    self.mapView.callout.leaderPositionFlags = AGSCalloutLeaderPositionAny;
    [self.mapView.callout showCalloutAtPoint:AGSPointWithReferenceFromCLLocationCoordinate(annotation.coordinate, self.mapView.spatialReference)
                                  forGraphic:layerAnnotation.graphic
                                    animated:YES];
}

- (void)showCalloutWithView:(UIView *)view
              forAnnotation:(id <MGSAnnotation>)annotation {
    self.mapView.callout.customView = view;
    [self showCalloutForAnnotation:annotation];
}

- (void)hideCallout {
    self.mapView.callout.hidden = YES;
}


#pragma mark - AGSMapViewLayerDelegate (10.x)
- (void)layerDidLoad:(AGSLayer *)loadedLayer {

}

- (void)layer:(AGSLayer *)loadedLayer didInitializeSpatialReferenceStatus:(BOOL)srStatusValid {
    if (srStatusValid) {
        DDLogVerbose(@"initialized spatial reference for layer '%@' to %d", loadedLayer.name, [loadedLayer.spatialReference wkid]);
    } else {
        DDLogError(@"failed to initialize spatial reference for layer '%@'", loadedLayer.name);
        [self.coreLayers removeObjectForKey:loadedLayer.name];
        [self.mapView removeMapLayer:loadedLayer];
    }

    // Perform the coreLayersLoaded checking here since we don't want to add any of the
    // user layers until we actually have a spatial reference to work with.
    if (self.coreLayers[loadedLayer.name] != nil) {
        if (self.coreLayersLoaded == NO) {
            __block BOOL layersLoaded = YES;
            [self.coreLayers enumerateKeysAndObjectsUsingBlock:^(NSString *name, AGSLayer *layer, BOOL *stop) {
                layersLoaded = (layersLoaded && layer.loaded);
            }];


            // Check again after we iterate through everything to make sure the state
            // hasn't changed now that we have another layer loaded
            if (layersLoaded) {
                self.coreLayersLoaded = YES;
                self.userLayerQueue.suspended = NO;
            }
        }
    }
}

- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error {
    DDLogError(@"failed to load layer '%@': %@", layer.name, [error localizedDescription]);
    [self.coreLayers removeObjectForKey:layer.name];
    [self.mapView removeMapLayer:layer];
}

#pragma mark - AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *)mapView {
    DDLogVerbose(@"basemap loaded with WKID %d", mapView.spatialReference.wkid);

    AGSEnvelope *maxEnvelope = [AGSEnvelope envelopeWithXmin:-7915909.671294
                                                        ymin:5212249.807534
                                                        xmax:-7912606.241692
                                                        ymax:5216998.487588
                                            spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
    AGSEnvelope *projectedEnvelope = (AGSEnvelope *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:maxEnvelope
                                                                                             toSpatialReference:mapView.spatialReference];
    [mapView setMaxEnvelope:projectedEnvelope];
    [mapView zoomToEnvelope:projectedEnvelope
                   animated:YES];
    [self didFinishLoadingMapView];
}

#pragma mark - AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    DDLogVerbose(@"Got a tap, found %d graphics", [graphics count]);
}


#pragma mark - MGSMapView Delegate Forwarding
- (void)didFinishLoadingMapView {
    if ([self.mapViewDelegate respondsToSelector:@selector(didFinishLoadingMapView:)]) {
        [self.mapViewDelegate didFinishLoadingMapView:self];
    }
}

- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willShowCalloutForAnnotation:)]) {
        [self.mapViewDelegate mapView:self
         willShowCalloutForAnnotation:annotation];
    }
}

- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didShowCalloutForAnnotation:)]) {
        [self.mapViewDelegate mapView:self
          didShowCalloutForAnnotation:annotation];
    }
}

- (void)calloutAccessoryDidReceiveTapForAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:calloutAccessoryDidReceiveTapForAnnotation:)]) {
        [self.mapViewDelegate      mapView:self
calloutAccessoryDidReceiveTapForAnnotation:annotation];
    }
}

- (void)willAddLayer:(MGSLayer *)layer {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willAddLayer:)]) {
        [self.mapViewDelegate mapView:self
                         willAddLayer:layer];
    }
}

- (void)didAddLayer:(MGSLayer *)layer {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didAddLayer:)]) {
        [self.mapViewDelegate mapView:self
                          didAddLayer:layer];
    }
}

- (void)willRemoveLayer:(MGSLayer *)layer {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:willRemoveLayer:)]) {
        [self.mapViewDelegate mapView:self
                      willRemoveLayer:layer];
    }
}

- (void)didRemoveLayer:(MGSLayer *)layer {
    if ([self.mapViewDelegate respondsToSelector:@selector(mapView:didRemoveLayer:)]) {
        [self.mapViewDelegate mapView:self
                       didRemoveLayer:layer];
    }
}
@end
