#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"
#import "MGSMapView+Delegation.h"

#import "MGSUtility.h"
#import "MGSLayer.h"
#import "MGSLayer+AGS.h"
#import "MGSCalloutView.h"

#import "MobileRequestOperation.h"

static NSString *const kMGSMapDefaultLayerIdentifier = @"edu.mit.mobile.map.Default";

@interface MGSMapView () <AGSMapViewTouchDelegate, AGSCalloutDelegate, AGSMapViewLayerDelegate, AGSMapViewCalloutDelegate, AGSLayerDelegate>
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
@property(nonatomic, weak) AGSMapView *mapView;
@property(strong) MGSLayer *defaultLayer;
@property(nonatomic,strong) id<MGSAnnotation> calloutAnnotation;

- (void)initView;
@end

@implementation MGSMapView

@dynamic mapSets;
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
            view.layerDelegate = self;
            view.touchDelegate = self;
            view.calloutDelegate = self;
            
            
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

- (NSArray*)layers {
    return [NSArray arrayWithArray:self.userLayerOrder];
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
        [self.userLayers enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, MGSLayer *layer, BOOL *stop) {
            NSUInteger index = NSNotFound;
            if ([layer isEqual:foregroundLayer]) {
                index = [self.layers indexOfObject:layerIdentifier];
            }
            
            if (index == NSNotFound) {
                [self addLayer:layer
                withIdentifier:layerIdentifier];
            } else {
                [self insertLayer:layer
                   withIdentifier:layerIdentifier
                          atIndex:index];
            }
        }];
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
            [self.userLayerOrder insertObject:layerIdentifier
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
        [self.userLayerOrder removeObject:layerIdentifier];
        
        [self.mapView addMapLayer:agsLayer
                         withName:layerIdentifier];
        [self.userLayerOrder addObject:layerIdentifier];
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
- (BOOL)showCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    if (self.calloutAnnotation) {
        [self hideCallout];
    }
    
    if ([self shouldShowCalloutForAnnotation:annotation]) {
        MGSLayer *layer = [self layerContainingAnnotation:annotation];
        AGSGraphic *graphic = [layer graphicForAnnotation:annotation];
        UIView *customView = [self calloutViewForAnnotation:annotation];
        
        if (customView) {
            self.mapView.callout.customView = customView;
        } else if (graphic.infoTemplateDelegate == nil) {
            MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
            self.mapView.callout.title = safeAnnotation.title;
            self.mapView.callout.detail = safeAnnotation.detail;
            self.mapView.callout.image = safeAnnotation.calloutImage;
        }
        
        [self willShowCalloutForAnnotation:annotation];
        self.calloutAnnotation = annotation;
        
        self.mapView.callout.delegate = self;
        [self.mapView.callout showCalloutAtPoint:nil
                                      forGraphic:graphic
                                        animated:YES];
        [self didShowCalloutForAnnotation:annotation];
    }
    
    
    return NO;
}

- (void)hideCallout {
    [self.mapView.callout dismiss];
    [self didDismissCalloutForAnnotation:self.calloutAnnotation];
    self.calloutAnnotation = nil;
}

- (MGSLayer*)layerContainingAnnotation:(id<MGSAnnotation>)annotation {
    id<MGSAnnotation> theAnnotation = annotation;
    
    if ([annotation respondsToSelector:@selector(annotation)]) {
        theAnnotation = [annotation performSelector:@selector(annotation)];
    }
    
    
    __block MGSLayer *myLayer = nil;
    [self.layers enumerateObjectsWithOptions:NSEnumerationReverse
                                  usingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
                                      MGSLayer *layer = [self layerWithIdentifier:identifier];
                                      
                                      if ([layer.annotations containsObject:theAnnotation]) {
                                          myLayer = layer;
                                          (*stop) = YES;
                                      }
                                  }];
    
    return myLayer;
}

- (MGSLayer*)layerContainingGraphic:(AGSGraphic*)graphic {
    __block MGSLayer *myLayer = nil;
    [self.layers enumerateObjectsWithOptions:NSEnumerationReverse
                                  usingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
                                      MGSLayer *layer = [self layerWithIdentifier:identifier];
                                      
                                      if ([layer annotationForGraphic:graphic]) {
                                          myLayer = layer;
                                          (*stop) = YES;
                                      }
                                  }];
    
    return myLayer;
}
@end

#pragma mark -
@implementation MGSMapView (AGSMapViewLayerDelegate)
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
}
@end

#pragma mark -
@implementation MGSMapView (AGSMapViewCalloutDelegate)
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic {
    MGSLayer *myLayer = [self layerContainingGraphic:graphic];
    id<MGSAnnotation> annotation = [myLayer annotationForGraphic:graphic];
    BOOL result = NO;
    
    result = [self shouldShowCalloutForAnnotation:annotation];
    
    if (result) {
        UIView *customView = [self calloutViewForAnnotation:annotation];
        
        if (customView || graphic.infoTemplateDelegate) {
            [self willShowCalloutForAnnotation:annotation];
            
            if (customView) {
                self.mapView.callout.customView = customView;
            }
        }
    }
    
    if (result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showCalloutForAnnotation:annotation];
        });
    }
    
    return NO;
}

- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForLocationDisplay:(AGSLocationDisplay *)ld {
    return NO;
}

- (void)mapViewWillDismissCallout:(AGSMapView *)mapView {
}

- (void)mapViewDidDismissCallout:(AGSMapView *)mapView {
    if (self.calloutAnnotation) {
        [self didDismissCalloutForAnnotation:self.calloutAnnotation];
        self.calloutAnnotation = nil;
    }
}
@end

#pragma mark -
@implementation MGSMapView (AGSMapViewTouchDelegate)
- (BOOL)mapView:(AGSMapView*)mapView shouldProcessClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint {
    return YES;
}

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    
}

- (void)mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    
}

- (void)mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    
}

- (void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    
}

- (void)mapViewDidCancelTapAndHold:(AGSMapView *)mapView {
    
}
@end

@implementation MGSMapView (AGSCalloutDelegate)
- (void)didClickAccessoryButtonForCallout:(AGSCallout *)callout {
    if (self.calloutAnnotation) {
        [self calloutDidReceiveTapForAnnotation:self.calloutAnnotation];
    }
}

@end

#pragma mark -
@implementation MGSMapView (AGSLayerDelegate)
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
                [self didFinishLoadingMapView];
            }
        }
    }
}

- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error {
    DDLogError(@"failed to load layer '%@': %@", layer.name, [error localizedDescription]);
    [self.coreLayers removeObjectForKey:layer.name];
    [self.mapView removeMapLayer:layer];
}
@end

#pragma mark -
@implementation MGSMapView (DelegateHelpers)
#pragma mark Callout Handling
- (BOOL)shouldShowCalloutForAnnotation:(id<MGSAnnotation>)annotation {
    MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
    BOOL showCallout = ((safeAnnotation.annotationType == MGSAnnotationMarker) ||
                        (safeAnnotation.annotationType == MGSAnnotationPointOfInterest));
    
    if ([self.delegate respondsToSelector:@selector(mapView:shouldShowCalloutForAnnotation:)]) {
        showCallout = [self.delegate mapView:self
              shouldShowCalloutForAnnotation:annotation];
    }
    
    return showCallout;
}

- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.delegate respondsToSelector:@selector(mapView:willShowCalloutForAnnotation:)]) {
        [self.delegate mapView:self willShowCalloutForAnnotation:annotation];
    }
}

- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation {
    UIView *view = nil;
    MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
    
    if (annotation == nil) {
        return nil;
    }
    
    if (view == nil) {
        if ([self.delegate respondsToSelector:@selector(mapView:calloutViewForAnnotation:)]) {
            view = [self.delegate mapView:self calloutViewForAnnotation:annotation];
        }
    }
    
    // If the view is still nil, create a default one!
    if (view == nil) {
        MGSCalloutView *calloutView = [[MGSCalloutView alloc] init];
        
        calloutView.titleLabel.text = safeAnnotation.title;
        calloutView.detailLabel.text = safeAnnotation.detail;
        calloutView.imageView.image = safeAnnotation.calloutImage;
        
        // This view could potentially be hanging around for a long time,
        // we don't want strong references to the layer or the annotation
        __weak MGSMapView *weakSelf = self;
        __weak id<MGSAnnotation> weakAnnotation = annotation;
        calloutView.accessoryBlock = ^(id sender) {
            [weakSelf calloutDidReceiveTapForAnnotation:weakAnnotation];
        };        
    }
    
    return view;
}

- (void)calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation {
    if ([self.delegate respondsToSelector:@selector(mapView:calloutDidReceiveTapForAnnotation:)]) {
        [self.delegate mapView:self calloutDidReceiveTapForAnnotation:annotation];
    }
}

- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.delegate respondsToSelector:@selector(mapView:didShowCalloutForAnnotation:)]) {
        [self.delegate mapView:self didShowCalloutForAnnotation:annotation];
    }
}

- (void)didDismissCalloutForAnnotation:(id<MGSAnnotation>)annotation {
    if ([self.delegate respondsToSelector:@selector(mapView:didDismissCalloutForAnnotation:)]) {
        [self.delegate mapView:self didDismissCalloutForAnnotation:annotation];
    }
}

#pragma mark Layer Mutation
- (void)didFinishLoadingMapView {
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingMapView:)]) {
        [self.delegate didFinishLoadingMapView:self];
    }
}

- (void)willAddLayer:(MGSLayer *)layer {
    if ([self.delegate respondsToSelector:@selector(mapView:willAddLayer:)]) {
        [self.delegate mapView:self
                         willAddLayer:layer];
    }
}

- (void)didAddLayer:(MGSLayer *)layer {
    if ([self.delegate respondsToSelector:@selector(mapView:didAddLayer:)]) {
        [self.delegate mapView:self
                          didAddLayer:layer];
    }
}

- (void)willRemoveLayer:(MGSLayer *)layer {
    if ([self.delegate respondsToSelector:@selector(mapView:willRemoveLayer:)]) {
        [self.delegate mapView:self
                      willRemoveLayer:layer];
    }
}

- (void)didRemoveLayer:(MGSLayer *)layer {
    if ([self.delegate respondsToSelector:@selector(mapView:didRemoveLayer:)]) {
        [self.delegate mapView:self
                       didRemoveLayer:layer];
    }
}
@end