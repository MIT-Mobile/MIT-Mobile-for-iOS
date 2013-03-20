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
#pragma mark - Basemap Management (Declaration)
@property(assign) BOOL coreLayersLoaded;
@property(strong) NSMutableDictionary *coreLayers;
@property(strong) NSDictionary *coreMaps;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property(strong) NSMutableArray *userLayers;
@property(nonatomic, strong) NSOperationQueue *mapOperationQueue;

// Used when getting/setting the map region before the map layer loads
// If the map is not loaded, the cached region will contain the last
// region that was added to the operation queue. If no region was set and
// the map layer
@property(nonatomic) BOOL mapRegionWasSet;
@property(nonatomic) MKCoordinateRegion cachedRegion;
#pragma mark -

@property(strong) NSMutableDictionary *queryTasks;
@property(nonatomic, weak) AGSMapView *mapView;
@property(strong) MGSLayer *defaultLayer;
@property(nonatomic,strong) id<MGSAnnotation> calloutAnnotation;

- (void)initView;
- (void)coreLayersDidFinishLoading;
- (AGSEnvelope*)defaultVisibleArea;
- (AGSEnvelope*)defaultMaximumEnvelope;
@end

@implementation MGSMapView
@dynamic mapSets;
@dynamic showUserLocation;

+ (MGSZoomLevel)zoomLevelForMKCoordinateSpan:(MKCoordinateSpan)span {
	return log2(360.0f / span.longitudeDelta) - 1;
}

+ (MKCoordinateSpan)coordinateSpanForZoomLevel:(MGSZoomLevel)zoomLevel {
    CGFloat longitudeDelta = 360.0f / pow(2.0,zoomLevel + 1);
    CGFloat latitudeDelta = longitudeDelta;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    
    return span;
}

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
    
    self.mapOperationQueue = [[NSOperationQueue alloc] init];
    self.mapOperationQueue.maxConcurrentOperationCount = 1;
    self.mapOperationQueue.suspended = YES;
    
    self.userLayers = [NSMutableArray array];
    
    self.coreLayersLoaded = NO;
    
    self.defaultLayer = [[MGSLayer alloc] initWithName:@"Default"];
    [self addLayer:self.defaultLayer];
    
    self.mapRegionWasSet = NO;

    // Make sure that we don't do draw anything outside the bounds of the window.
    // The ArcGIS SDK has a really annoying bug where it will happily draw a presented
    // callout anywhere on the screen, even if the view isn't there. To see this, disable masksToBounds,
    // create a map view shorter than the screen height, present a callout and then drag the map
    // around. The callout will be drawn (and tracked!) even if it leaves the map view
    self.layer.masksToBounds = YES;
    
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


- (AGSEnvelope*)defaultVisibleArea {
    return [AGSEnvelope envelopeWithXmin:-7916712.379879861
                                    ymin:5214115.052300519
                                    xmax:-7911452.543710185
                                    ymax:5217411.40739323
                        spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
}

- (AGSEnvelope*)defaultMaximumEnvelope {
    return [AGSEnvelope envelopeWithXmin:-7920689.320999366
                                    ymin:5211048.119330198
                                    xmax:-7907475.602590679
                                    ymax:5219026.033192276
                        spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
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
#pragma mark -

#pragma mark - Dynamic Properties
- (MGSZoomLevel)zoomLevel {
    return [MGSMapView zoomLevelForMKCoordinateSpan:self.mapRegion.span];
}

- (void)setZoomLevel:(MGSZoomLevel)zoomLevel {
    MKCoordinateRegion region = self.mapRegion;
    region.span = [MGSMapView coordinateSpanForZoomLevel:zoomLevel];
    
    self.mapRegion = region;
}

- (void)setShowUserLocation:(BOOL)showUserLocation
{
    if (showUserLocation) {
        [self.mapView.locationDisplay startDataSource];
        self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeOff;
        self.mapView.locationDisplay.dataSource.delegate = self;
    }
    else {
        [self.mapView.locationDisplay stopDataSource];
    }

}

- (BOOL)showUserLocation
{
    return self.mapView.locationDisplay.dataSource && self.mapView.locationDisplay.isDataSourceStarted;
}

- (MKCoordinateRegion)mapRegion {
    if (self.mapRegionWasSet) {
        return self.cachedRegion;
    }

    AGSEnvelope *regionEnvelope = nil;
    
    if(self.mapView.spatialReference != nil) {
        regionEnvelope = [self.mapView visibleAreaEnvelope];
        
        if ([regionEnvelope isEmpty] || ([regionEnvelope isValid] == NO)) {
            regionEnvelope = [self defaultVisibleArea];
        }
    } else {
        regionEnvelope = [self defaultVisibleArea];
    }
    
    regionEnvelope = (AGSEnvelope*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:regionEnvelope
                                                           toSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
    
    MKCoordinateSpan span = MKCoordinateSpanMake(fabs(regionEnvelope.ymax - regionEnvelope.ymin),
                                                 fabs(regionEnvelope.xmax - regionEnvelope.xmin));
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(regionEnvelope.center.y, regionEnvelope.center.x);
    
    return MKCoordinateRegionMake(center, span);
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion {
    [self setMapRegion:mapRegion
              animated:NO];
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion animated:(BOOL)animated {
    BOOL mapRegionIsValid = ((CLLocationCoordinate2DIsValid(mapRegion.center)) &&
                              (mapRegion.span.latitudeDelta > 0) &&
                              (mapRegion.span.longitudeDelta > 0));
                             
    if (mapRegionIsValid == NO) {
        // If the region is invalid, don't change anything
#warning TODO: Make sure that doing nothing is a valid choice. Should we zoom to default instead?
        DDLogError(@"attempting to set a empty or invalid region.");
    } else {
        self.mapRegionWasSet = YES;
        self.cachedRegion = mapRegion;

        [self.mapOperationQueue addOperationWithBlock:^{
            AGSMutableEnvelope *envelope = [[AGSMutableEnvelope alloc] initWithSpatialReference:[AGSSpatialReference wgs84SpatialReference]];


            double offsetX = (mapRegion.span.longitudeDelta / 2.0);
            double offsetY = (mapRegion.span.latitudeDelta / 2.0);

            [envelope updateWithXmin:mapRegion.center.longitude - offsetX
                                ymin:mapRegion.center.latitude - offsetY
                                xmax:mapRegion.center.longitude + offsetX
                                ymax:mapRegion.center.latitude + offsetY];

            AGSGeometry *projectedGeometry = envelope;
            if ([envelope.spatialReference isEqualToSpatialReference:self.mapView.spatialReference] == NO) {
                projectedGeometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:envelope
                                                                            toSpatialReference:self.mapView.spatialReference];
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if ([projectedGeometry isValid] && ([projectedGeometry isEmpty] == NO)) {
                        [self.mapView zoomToGeometry:projectedGeometry
                                         withPadding:0.0
                                            animated:animated];
                } else {
                    // We should never get here but, just in case, make sure we react
                    // sanely if something went horribly wrong when re-projecting the envelope
                    [self.mapView zoomToGeometry:[self defaultVisibleArea]
                                         withPadding:0.0
                                            animated:animated];
                }
            }];
        }];
    }
}

- (NSArray*)mapLayers {
    return [NSArray arrayWithArray:self.userLayers];
}

- (BOOL)isPresentingCallout {
    return (self.calloutAnnotation != nil);
}

#pragma mark - Layer Management
- (void)addLayer:(MGSLayer*)newLayer {
    if (newLayer.mapView != nil) {
        DDLogError(@"attempting to add layer '%@' but it is already owned by a map view", newLayer.name);
    } else {
        [self.mapOperationQueue addOperationWithBlock:^{
            if ([self containsLayer:newLayer] == NO) {
                if (newLayer.graphicsLayer == nil) {
                    [newLayer loadGraphicsLayer];
                }
                
                [self willAddLayer:newLayer];
            
                newLayer.mapView = self;
                [self.userLayers addObject:newLayer];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.mapView addMapLayer:newLayer.graphicsLayer];
                }];
                
                [self didAddLayer:newLayer];
                
                [self moveLayer:self.defaultLayer
                        toIndex:NSUIntegerMax];
            } else {
                DDLogError(@"layer '%@' already exists in map view", newLayer.name);
            }
        }];
    }
}

- (void)moveLayer:(MGSLayer*)aLayer
          toIndex:(NSUInteger)newIndex {
    if ([self containsLayer:aLayer] && (aLayer.mapView == self)) {
        [self.mapOperationQueue addOperationWithBlock:^{
            NSUInteger currentIndex = [self.userLayers indexOfObject:aLayer];
            
            if (currentIndex == NSNotFound) {
                DDLogError(@"attempting to move layer '%@' to illegal index NSNotFound", aLayer.name);
            } else if (currentIndex != newIndex) {
                
                // Make sure we check to see if the index
                // we are inserting at is still valid and
                // apply any needed corrections.
                NSUInteger insertIndex = newIndex;
                
                // If the index we are trying to insert at
                // is out of bounds, assume that the user wants
                // to move the layer to the top of the view
                // hierarchy, not crash.
                if (newIndex >= [self.userLayers count]) {
                    insertIndex = [self.userLayers count];
                } else if (currentIndex < newIndex) {
                    // The new index will be shifted by 1 toward 0
                    // since we are deleting the layer a few lines up
                    --insertIndex;
                }
                
                
                [self.userLayers removeObject:aLayer];
                [self.userLayers insertObject:aLayer
                                      atIndex:insertIndex - 1];
                
                NSInteger agsIndex = ([self.coreLayers count] - 1) + insertIndex;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.mapView removeMapLayer:aLayer.graphicsLayer];
                    
                    DDLogVerbose(@"moving layer '%@' to index %d (%d) from (%d)", aLayer.name, agsIndex, insertIndex, currentIndex);
                    [self.mapView insertMapLayer:aLayer.graphicsLayer
                                         atIndex:agsIndex];
                }];
            }
        }];
    } else {
        DDLogError(@"attempting to relocate layer '%@' but it is already owned by another map view", aLayer.name);
    }
}

- (void)insertLayer:(MGSLayer*)newLayer
            atIndex:(NSUInteger)aIndex {
    if (newLayer.mapView != nil) {
        DDLogError(@"attempting to add layer '%@' but it is already owned by a map view", newLayer.name);
    } else if (aIndex == NSNotFound) {
        DDLogError(@"attempting to add layer '%@' to illegal index NSNotFound", newLayer.name);
    } else {
        [self.mapOperationQueue addOperationWithBlock:^{
            if ([self containsLayer:newLayer] == NO) {
                // If the index we are trying to insert at
                // is out of bounds, assume that the user wants
                // to move the layer to the top of the view
                // hierarchy, not crash.
                NSUInteger insertIndex = aIndex;
                if (aIndex > [self.userLayers count]) {
                    insertIndex = [self.userLayers count];
                }
                
                // Calculate the index used to insert the layer
                // into the ArcGIS view. Since there could be 0 or more
                // base layers
                NSInteger agsIndex = ([self.coreLayers count] - 1) + insertIndex;
                if (newLayer.graphicsLayer == nil) {
                    [newLayer loadGraphicsLayer];
                }
                
                [self willAddLayer:newLayer];
                
                newLayer.mapView = self;
                [self.userLayers insertObject:newLayer
                                      atIndex:insertIndex];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.mapView insertMapLayer:newLayer.graphicsLayer
                                         atIndex:agsIndex];
                }];
                
                [self didAddLayer:newLayer];
                
                [self moveLayer:self.defaultLayer
                        toIndex:NSUIntegerMax];
            } else {
                DDLogError(@"layer '%@' already exists in map view", newLayer.name);
            }
        }];
    }
}


- (void)insertLayer:(MGSLayer*)newLayer
        behindLayer:(MGSLayer*)foregroundLayer {
    if (newLayer.mapView != nil) {
        DDLogError(@"attempting to add layer '%@' but it is already owned by another map view", newLayer.name);
    } else {
        [self.mapOperationQueue addOperationWithBlock:^{
            if (foregroundLayer && [self containsLayer:foregroundLayer] == NO) {
                DDLogError(@"attempting to add layer '%@' behind an invalid layer (%@)",newLayer.name,foregroundLayer.name);
            } else if ([self containsLayer:newLayer] == NO) {
                NSUInteger fgIndex = [self.userLayers indexOfObject:foregroundLayer];
                [self insertLayer:newLayer
                          atIndex:fgIndex];
            }
        }];
    }
}

- (BOOL)containsLayer:(MGSLayer *)layer {
    return [self.userLayers containsObject:layer];
}

- (void)removeLayer:(MGSLayer *)layer {
    [self.mapOperationQueue addOperationWithBlock:^{
        if (layer && [self containsLayer:layer]) {
            [self willRemoveLayer:layer];
            
            AGSLayer *graphicsLayer = layer.graphicsLayer;
            if (graphicsLayer) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.mapView removeMapLayer:graphicsLayer];
                }];
            }
            
            layer.graphicsLayer = nil;
            layer.mapView = nil;
            [self.userLayers removeObject:layer];
            
            [self didRemoveLayer:layer];
        }
    }];
}

- (BOOL)isLayerHidden:(MGSLayer*)layer {
    return (layer.graphicsLayer.visible == NO);
}

- (void)setHidden:(BOOL)hidden forLayer:(MGSLayer *)layer {
     layer.graphicsLayer.visible = !hidden;
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate {
    [self centerAtCoordinate:coordinate
                    animated:YES];
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate
                  animated:(BOOL)animated
{
    MKCoordinateSpan span = [MGSMapView coordinateSpanForZoomLevel:self.zoomLevel];
    
    [self setMapRegion:MKCoordinateRegionMake(coordinate, span)
              animated:animated];
}


- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate {
    DDLogVerbose(@"Spatial Reference: %@", self.mapView.spatialReference);
    
    if (self.mapView.spatialReference) {
        return [self.mapView toScreenPoint:AGSPointWithReferenceFromCLLocationCoordinate(coordinate, self.mapView.spatialReference)];
    } else {
        return CGPointZero;
    }
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
    [self.mapLayers enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(MGSLayer *layer, NSUInteger idx, BOOL *stop) {
                                      
                                      if ([layer.annotations containsObject:theAnnotation]) {
                                          myLayer = layer;
                                          (*stop) = YES;
                                      }
                                  }];
    
    return myLayer;
}

- (MGSLayer*)layerContainingGraphic:(AGSGraphic*)graphic {
    __block MGSLayer *myLayer = nil;
    [self.mapLayers enumerateObjectsWithOptions:NSEnumerationReverse
                                  usingBlock:^(MGSLayer *layer, NSUInteger idx, BOOL *stop) {
                                      
                                      if ([layer annotationForGraphic:graphic]) {
                                          myLayer = layer;
                                          (*stop) = YES;
                                      }
                                  }];
    
    return myLayer;
}

- (void)coreLayersDidFinishLoading {
    [self didFinishLoadingMapView];
    self.mapOperationQueue.suspended = NO;
}
@end

#pragma mark -
@implementation MGSMapView (AGSMapViewLayerDelegate)
- (void)mapViewDidLoad:(AGSMapView *)mapView {
    DDLogVerbose(@"basemap loaded with WKID %d", mapView.spatialReference.wkid);
    
    AGSEnvelope *maxEnvelope = (AGSEnvelope *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:[self defaultMaximumEnvelope]
                                                                                       toSpatialReference:mapView.spatialReference];
    mapView.maxEnvelope = maxEnvelope;

    if (self.mapRegionWasSet == NO) {
        AGSEnvelope *visibleEnvelope = (AGSEnvelope *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:[self defaultVisibleArea]
                                                                                           toSpatialReference:mapView.spatialReference];
        [mapView zoomToEnvelope:visibleEnvelope
                       animated:YES];
    }
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
                [self coreLayersDidFinishLoading];
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

- (void)userLocationDidUpdate:(CLLocation*)location {
    if ([self.delegate respondsToSelector:@selector(mapView:userLocationDidUpdate:)]) {
        [self.delegate mapView:self
         userLocationDidUpdate:location];
    }
}


- (void)userLocationUpdateFailedWithError:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(mapView:userLocationUpdateFailedWithError:)]) {
        [self.delegate mapView:self
        userLocationUpdateFailedWithError:error];
    }
}
@end

@implementation MGSMapView (AGSLocationDisplayDataSourceDelegate)
- (void)locationDisplayDataSource:(id <AGSLocationDisplayDataSource>)dataSource
                 didFailWithError:(NSError *)error
{
    DDLogVerbose(@"Failed to locate user: %@", error);
    [self userLocationUpdateFailedWithError:error];

    // Forward the notification to the location display because
    // the SDK doesn't allow us to receive notifications from the
    // location data source and still automatically display
    // a marker on the map.
    [self.mapView.locationDisplay locationDisplayDataSource:dataSource
                                           didFailWithError:error];
}

- (void)locationDisplayDataSource:(id <AGSLocationDisplayDataSource>)dataSource
             didUpdateWithHeading:(double)heading
{
    [self.mapView.locationDisplay locationDisplayDataSource:dataSource
                                       didUpdateWithHeading:heading];
}

- (void)locationDisplayDataSource:(id <AGSLocationDisplayDataSource>)dataSource
            didUpdateWithLocation:(AGSLocation *)location
{
    CLLocation *clLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinateFromAGSPoint(location.point)
                                                           altitude:0.0
                                                 horizontalAccuracy:location.accuracy
                                                   verticalAccuracy:location.accuracy
                                                             course:location.course
                                                              speed:location.velocity
                                                          timestamp:[NSDate date]];
    [self userLocationDidUpdate:clLocation];
    [self.mapView.locationDisplay locationDisplayDataSource:dataSource
                                  didUpdateWithLocation:location];
}

- (void)locationDisplayDataSourceStarted:(id <AGSLocationDisplayDataSource>)dataSource
{
    [self.mapView.locationDisplay locationDisplayDataSourceStarted:dataSource];
}

- (void)locationDisplayDataSourceStopped:(id <AGSLocationDisplayDataSource>)dataSource
{
    [self.mapView.locationDisplay locationDisplayDataSourceStopped:dataSource];
}
@end
