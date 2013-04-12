#import <ArcGIS/ArcGIS.h>
#import "MapKit+MITAdditions.h"

#import "MGSMapView.h"
#import "MGSMapView+Private.h"

#import "MGSUtility.h"
#import "MGSGeometry.h"
#import "MGSLayer.h"
#import "MGSCalloutView.h"

#import "MobileRequestOperation.h"
#import "MGSLayerController.h"
#import "MGSSafeAnnotation.h"
#import "MGSLayerAnnotation.h"
#import "MGSBootstrapper.h"


@implementation MGSMapView
{
    // Defined an ivar since the mapRegion property is marked
    // as dynamic and clang won't create one for us
    MKCoordinateRegion _mapRegion;
}

@dynamic mapSets;
@dynamic showUserLocation;

@dynamic zoomLevel;
@dynamic centerCoordinate;
@dynamic mapRegion;

#pragma mark - Public
#pragma mark Initialization
- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

#pragma mark Base Map Set Management
- (NSSet*)mapSets
{
    return [NSSet setWithArray:[self.baseMapGroups allKeys]];
}

- (NSString*)nameForMapSetWithIdentifier:(NSString*)mapSetIdentifier
{
    NSDictionary* layerInfo = self.baseMapGroups[mapSetIdentifier];
    return layerInfo[@"displayName"];
}

- (void)setActiveMapSet:(NSString*)mapSetName
{
    if (self.baseMapGroups[mapSetName]) {
        NSMutableDictionary* coreMapLayers = [NSMutableDictionary dictionary];
        NSMutableArray* identifierOrder = [NSMutableArray array];
        
        for (NSDictionary* layerInfo in self.baseMapGroups[mapSetName]) {
            NSString* displayName = layerInfo[@"displayName"];
            NSString* identifier = layerInfo[@"layerIdentifier"];
            NSURL* layerURL = [NSURL URLWithString:layerInfo[@"url"]];
            
            DDLogVerbose(@"adding core layer '%@' [%@]", displayName, identifier);
            
            AGSTiledMapServiceLayer* serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            serviceLayer.delegate = self;
            
            coreMapLayers[identifier] = serviceLayer;
            [identifierOrder addObject:identifier];
        }
        
        [self.baseLayers.allKeys enumerateObjectsUsingBlock:^(NSString* layerName, NSUInteger idx, BOOL* stop) {
            [self.mapView removeMapLayerWithName:layerName];
        }];
        
        [identifierOrder enumerateObjectsUsingBlock:^(NSString* layerName, NSUInteger idx, BOOL* stop) {
            [self.mapView insertMapLayer:coreMapLayers[layerName]
                                withName:layerName
                                 atIndex:idx];
        }];
        
        self.baseLayers = coreMapLayers;
        _activeMapSet = mapSetName;
    }
}


#pragma mark Visible Region
- (MKCoordinateRegion)mapRegion
{
    MKCoordinateRegion region = _mapRegion;
    
    if (MKCoordinateRegionIsValid(region) == NO) {
        if (self.isBaseLayersLoaded) {
            region = MKCoordinateRegionFromAGSEnvelope(self.mapView.visibleAreaEnvelope);
        } else {
            region = [self defaultVisibleArea];
        }
    }
    
    return region;
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion
{
    [self setMapRegion:mapRegion
              animated:NO];
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion
            animated:(BOOL)animated
{
    if (MKCoordinateRegionIsValid(mapRegion) == NO) {
        DDLogError(@"attempted to set a empty or invalid region");
    } else {
        _mapRegion = mapRegion;
        
        if (self.isBaseLayersLoaded) {
            AGSEnvelope *regionEnvelope = AGSEnvelopeFromMKCoordinateRegionWithSpatialReference(mapRegion,
                                                                                                self.mapView.spatialReference);
            
            if (regionEnvelope == nil) {
                MITLogFatal(@"**critical** envelope returned is invalid but the requested region was valid. Falling back to defaults");
                regionEnvelope = AGSEnvelopeFromMKCoordinateRegionWithSpatialReference([self defaultVisibleArea],
                                                                                       self.mapView.spatialReference);
            }
            
            [self.mapView zoomToEnvelope:regionEnvelope
                                animated:animated];
        }
    }
}

- (MGSZoomLevel)zoomLevel
{
    return MGSZoomLevelForMKCoordinateSpan(self.mapRegion.span);
}

- (void)setZoomLevel:(MGSZoomLevel)zoomLevel
{
    [self setZoomLevel:zoomLevel
              animated:NO];
}

- (void)setZoomLevel:(MGSZoomLevel)zoomLevel
            animated:(BOOL)animated
{
    MKCoordinateRegion region = self.mapRegion;
    region.span = MKCoordinateSpanForMGSZoomLevel(zoomLevel);
    [self setMapRegion:region
              animated:animated];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return self.mapRegion.center;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self setCenterCoordinate:coordinate
                     animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate
                   animated:(BOOL)animated
{
    MKCoordinateRegion mapRegion = self.mapRegion;
    mapRegion.center = coordinate;
    [self setMapRegion:mapRegion
              animated:animated];
}


#pragma mark Misc
- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self.isBaseLayersLoaded) {
        AGSPoint *mapPoint = AGSPointFromCLLocationCoordinate2DInSpatialReference(coordinate, self.mapView.spatialReference);
        return [self.mapView toScreenPoint:mapPoint];
    } else {
        return CGPointZero;
    }
}

- (BOOL)showUserLocation {
    return (self.mapView.locationDisplay.dataSource &&
            self.mapView.locationDisplay.isDataSourceStarted);

}

- (void)setShowUserLocation:(BOOL)showUserLocation {
    if (showUserLocation) {
        [self.mapView.locationDisplay startDataSource];
        self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeOff;
        self.mapView.locationDisplay.dataSource.delegate = self;
    } else {
        [self.mapView.locationDisplay stopDataSource];
    }
}


#pragma mark Layer Management
- (NSArray*)mapLayers
{
    return [NSArray arrayWithArray:self.externalLayers];
}

- (void)refreshLayer:(MGSLayer*)layer
{
    [self refreshLayers:[NSSet setWithObject:layer]];
}

- (void)refreshLayers:(NSSet*)layers
{
    if (self.isBaseLayersLoaded) {
        NSArray *sortedArrays = [[layers allObjects] sortedArrayUsingComparator:^NSComparisonResult(MGSLayer *layer1, MGSLayer *layer2) {
            NSUInteger index1 = [self.externalLayers indexOfObject:layer1];
            NSUInteger index2 = [self.externalLayers indexOfObject:layer2];
            
            if (index1 < index2) {
                return NSOrderedAscending;
            } else if (index2 < index1) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
        
        [sortedArrays enumerateObjectsUsingBlock:^(MGSLayer *layer, NSUInteger idx, BOOL *stop) {
            NSUInteger layerIndex = [self.externalLayers indexOfObject:layer];
            
            if (layerIndex != NSNotFound) {
                MGSLayerController *manager = [self layerManagerForLayer:layer];
                manager.spatialReference = self.mapView.spatialReference;
                
                AGSLayer *arcgisLayer = manager.nativeLayer;
                NSUInteger agsLayerIndex = [self.baseLayers count] + layerIndex;
                
                if ([self.mapView.mapLayers containsObject:arcgisLayer] == NO) {
                    arcgisLayer.delegate = self;
                    [self.mapView insertMapLayer:arcgisLayer
                                        withName:layer.name
                                         atIndex:agsLayerIndex];
                }
                
                [manager refresh];
            }
        }];
    }
}

- (BOOL)isLayerHidden:(MGSLayer*)layer
{
    MGSLayerController* manager = [self layerManagerForLayer:layer];
    return (manager.nativeLayer.isVisible);
}

- (void)setHidden:(BOOL)hidden
         forLayer:(MGSLayer*)layer
{
    MGSLayerController* manager = [self layerManagerForLayer:layer];
    manager.nativeLayer.visible = !hidden;
}


#pragma mark Adding Layers
- (void)addLayer:(MGSLayer*)newLayer
{
    [self insertLayer:newLayer
              atIndex:[self.externalLayers count]
 shouldNotifyDelegate:YES];
}

- (void)insertLayer:(MGSLayer*)layer
        behindLayer:(MGSLayer*)foregroundLayer
{
    NSUInteger layerIndex = [self.externalLayers indexOfObject:foregroundLayer];
    
    if (layerIndex != NSNotFound) {
        [self insertLayer:layer
                  atIndex:layerIndex];
    }
}

- (void)insertLayer:(MGSLayer*)newLayer
            atIndex:(NSUInteger)index
{
    [self insertLayer:newLayer
              atIndex:index
 shouldNotifyDelegate:YES];
}

- (void)insertLayer:(MGSLayer*)newLayer
            atIndex:(NSUInteger)index
shouldNotifyDelegate:(BOOL)notifyDelegate
{
    MGSLayerController* layerManager = [self layerManagerForLayer:newLayer];
    
    if ([self.externalLayers containsObject:newLayer] == NO) {
        if (layerManager == nil) {
            layerManager = [[MGSLayerController alloc] initWithLayer:newLayer];
            layerManager.delegate = self;
            [self.externalLayerManagers addObject:layerManager];
        }
        
        if (notifyDelegate) {
            [self willAddLayer:newLayer];
        }
        
        [self.externalLayers insertObject:newLayer
                                  atIndex:index];
        
        if (notifyDelegate) {
            [self didAddLayer:newLayer];
        }
        
        [self moveLayer:self.defaultLayer
                toIndex:[self.externalLayers count]];
    }
    
    // The map view will only have a spatial reference once it has been loaded
    if (self.isBaseLayersLoaded) {
        [self refreshLayer:newLayer];
    }
}

#pragma mark Removing Layers
- (void)removeLayer:(MGSLayer*)layer
{
    [self removeLayer:layer
  shoulNotifyDelegate:YES];
}

- (void)removeLayer:(MGSLayer*)layer
shoulNotifyDelegate:(BOOL)notifyDelegate
{
    MGSLayerController* layerManager = [self layerManagerForLayer:layer];
    
    if (layerManager == nil) {
        DDLogError(@"external layers out of sync during removal of '%@'", layer.name);
    }
    
    if (layer) {
        if (notifyDelegate) {
            [self willRemoveLayer:layer];
        }
        
        [self.externalLayers removeObject:layer];
        [self.externalLayerManagers removeObject:layerManager];
        
        if (layerManager.nativeLayer) {
            [self.mapView removeMapLayer:layerManager.nativeLayer];
        }
        
        if (notifyDelegate) {
            [self didRemoveLayer:layer];
        }
        
        [self moveLayer:self.defaultLayer
                toIndex:[self.externalLayers count]];
    }
}

#pragma mark Layer Reorganization
- (void)moveLayer:(MGSLayer*)layer
          toIndex:(NSUInteger)newIndex
{
    NSUInteger layerIndex = [self.externalLayers indexOfObject:layer];
    
    if (newIndex > layerIndex) {
        // Subtract 1 from the new index because we need to remove
        // the layer before moving it.
        newIndex -= 1;
    }
    
    if ((layerIndex != NSNotFound) && (layerIndex != newIndex)) {
        [self removeLayer:layer
      shoulNotifyDelegate:NO];
        
        [self insertLayer:layer
                  atIndex:newIndex
     shouldNotifyDelegate:NO];
    }
}

#pragma mark Callout Handling
- (BOOL)isPresentingCallout
{
    return (self.calloutAnnotation && self.mapView.callout.representedObject);
}

- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    [self showCalloutForAnnotation:annotation
                          recenter:YES
                          animated:YES];
}

- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation
                        recenter:(BOOL)recenter
                        animated:(BOOL)animated
{
    if (self.isBaseLayersLoaded == NO) {
        self.pendingCalloutAnnotation = annotation;
    } else {
        if ([self shouldShowCalloutForAnnotation:annotation]) {
            [self willShowCalloutForAnnotation:annotation];
            
            MGSLayer* layer = [self layerContainingAnnotation:annotation];
            MGSLayerController* manager = [self layerManagerForLayer:layer];
            AGSGraphic* graphic = [[manager layerAnnotationForAnnotation:annotation] graphic];
            UIView* customView = [self calloutViewForAnnotation:annotation];
            
            if (graphic == nil) {
                return;
            } else if (customView) {
                self.mapView.callout.customView = customView;
            } else if (graphic.infoTemplateDelegate == nil) {
                MGSSafeAnnotation* safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
                self.mapView.callout.title = safeAnnotation.title;
                self.mapView.callout.detail = safeAnnotation.detail;
                self.mapView.callout.image = safeAnnotation.calloutImage;
            }
            
            self.calloutAnnotation = annotation;
            
            [self willShowCalloutForAnnotation:annotation];
            self.mapView.callout.delegate = self;
            
            [UIView animateWithDuration:0.5
                                  delay:0
                                options:(UIViewAnimationOptionOverrideInheritedCurve |
                                         UIViewAnimationOptionOverrideInheritedDuration |
                                         UIViewAnimationOptionAllowAnimatedContent |
                                         UIViewAnimationOptionBeginFromCurrentState)
                             animations:^{
                                 if (recenter) {
                                     [self.mapView centerAtPoint:graphic.geometry.envelope.center
                                                        animated:animated];
                                 }
                             }
             
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     [self.mapView.callout showCalloutAtPoint:graphic.geometry.envelope.center
                                                                   forGraphic:graphic
                                                                     animated:animated];
                                     [self didShowCalloutForAnnotation:annotation];
                                 }
                             }]; 
            
            
        }
    }
}

- (void)dismissCallout
{
    [self.mapView.callout dismiss];
    [self didDismissCalloutForAnnotation:self.calloutAnnotation];
    self.calloutAnnotation = nil;
}


#pragma mark - Delegation
#pragma mark Map State
- (void)didFinishLoadingMapView
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(didFinishLoadingMapView:)]) {
            [self.delegate didFinishLoadingMapView:self];
        }
    }];
}

#pragma mark Layer Mutation
- (void)willAddLayer:(MGSLayer*)layer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:willAddLayer:)]) {
            [self.delegate mapView:self
                      willAddLayer:layer];
        }
        
        [layer willAddLayerToMapView:self];
    }];
}

- (void)didAddLayer:(MGSLayer*)layer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:didAddLayer:)]) {
            [self.delegate mapView:self
                       didAddLayer:layer];
        }
        
        [layer didAddLayerToMapView:self];
    }];
}

- (void)willRemoveLayer:(MGSLayer*)layer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:willRemoveLayer:)]) {
            [self.delegate mapView:self
                   willRemoveLayer:layer];
        }
        
        [layer willRemoveLayerFromMapView:self];
    }];
}

- (void)didRemoveLayer:(MGSLayer*)layer
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:didRemoveLayer:)]) {
            [self.delegate mapView:self
                    didRemoveLayer:layer];
        }
        
        [layer didRemoveLayerFromMapView:self];
    }];
}


#pragma mark Callout
- (BOOL)shouldShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    MGSSafeAnnotation* safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
    BOOL showCallout = ((safeAnnotation.annotationType == MGSAnnotationMarker) ||
                        (safeAnnotation.annotationType == MGSAnnotationPointOfInterest));
    
    if ([self.delegate respondsToSelector:@selector(mapView:shouldShowCalloutForAnnotation:)]) {
        showCallout = [self.delegate mapView:self
              shouldShowCalloutForAnnotation:annotation];
    }
    
    return showCallout;
}

- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:willShowCalloutForAnnotation:)]) {
            [self.delegate mapView:self willShowCalloutForAnnotation:annotation];
        }
    }];
}

- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:didShowCalloutForAnnotation:)]) {
            [self.delegate mapView:self didShowCalloutForAnnotation:annotation];
        }
    }];
}

- (void)didDismissCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:didDismissCalloutForAnnotation:)]) {
            [self.delegate mapView:self didDismissCalloutForAnnotation:annotation];
        }
    }];
}

- (UIView*)calloutViewForAnnotation:(id <MGSAnnotation>)annotation
{
    UIView* view = nil;
    if (annotation) {
        MGSSafeAnnotation* safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        if ([self.delegate respondsToSelector:@selector(mapView:calloutViewForAnnotation:)]) {
            view = [self.delegate mapView:self
                 calloutViewForAnnotation:annotation];
        }
        
        // If the view is still nil, create a default one!
        if (view == nil) {
            MGSCalloutView* calloutView = [[MGSCalloutView alloc] init];
            
            calloutView.titleLabel.text = safeAnnotation.title;
            calloutView.detailLabel.text = safeAnnotation.detail;
            calloutView.imageView.image = safeAnnotation.calloutImage;
            
            // This view could potentially be hanging around for a long time,
            // we don't want strong references to the layer or the annotation
            __weak MGSMapView* weakSelf = self;
            __weak id <MGSAnnotation> weakAnnotation = annotation;
            calloutView.accessoryBlock = ^(id sender) {
                [weakSelf calloutDidReceiveTapForAnnotation:weakAnnotation];
            };
        }
    }
    
    return view;
}

- (void)calloutDidReceiveTapForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([self.calloutAnnotation isEqual:annotation]) {
        [self dismissCallout];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:calloutDidReceiveTapForAnnotation:)]) {
            [self.delegate mapView:self calloutDidReceiveTapForAnnotation:annotation];
        }
    }];
}


#pragma mark Location Updates
- (void)userLocationDidUpdate:(CLLocation*)location
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:userLocationDidUpdate:)]) {
            [self.delegate mapView:self
             userLocationDidUpdate:location];
        }
    }];
}

- (void)userLocationUpdateFailedWithError:(NSError*)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:userLocationUpdateFailedWithError:)]) {
            [self.delegate mapView:self
 userLocationUpdateFailedWithError:error];
        }
    }];
}



#pragma mark - Private Methods
#pragma mark Properties

#pragma mark Initialization
- (void)commonInit
{
    // Use direct ivar access so we don't call the mutator
    self->_mapRegion = MKCoordinateRegionInvalid;
    
    self.baseLayersLoaded = NO;
    self.externalLayers = [NSMutableArray array];
    self.externalLayerManagers = [NSMutableSet set];
    
    // Make sure that we don't do draw anything outside the bounds of the window.
    // The ArcGIS SDK has a really annoying bug where it will happily draw a presented
    // callout anywhere on the screen, even if the view isn't there. To see this, disable masksToBounds,
    // create a map view shorter than the screen height, present a callout and then drag the map
    // around. The callout will be drawn (and tracked!) even if it leaves the map view
    self.layer.masksToBounds = YES;
    
    {
        self.backgroundColor = [UIColor lightGrayColor];
        CGRect mainBounds = self.bounds;
        
        {
            AGSMapView* view = [[AGSMapView alloc] initWithFrame:mainBounds];
            view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
            view.layerDelegate = self;
            view.touchDelegate = self;
            view.calloutDelegate = self;
            
            [self addSubview:view];
            self.mapView = view;
        }
        
        MGSBootstrapper *bootstrapper = [MGSBootstrapper sharedBootstrapper];
        [bootstrapper requestBootstrap:^(NSDictionary *content, NSError *error) {
            if (error) {
                DDLogError(@"failed to load basemap definitions: %@", error);
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Map Error"
                                                                    message:@"Failed to initialize the map."
                                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [alertView show];
            } else if ([content isKindOfClass:[NSDictionary class]]) {
                NSDictionary* response = (NSDictionary*) content;
                self.baseMapGroups = response[@"basemaps"];
                
                NSString* defaultSetName = response[@"defaultBasemap"];
                
                if ([defaultSetName length] == 0) {
                    defaultSetName = [[self.baseMapGroups allKeys] objectAtIndex:0];
                }
                
                self.activeMapSet = defaultSetName;
            }
        }];
        
    }

    self.defaultLayer = [[MGSLayer alloc] initWithName:@"Default"];
    [self addLayer:self.defaultLayer];
}

- (void)baseLayersDidFinishLoading
{
    self.baseLayersLoaded = YES;
    
    // Make sure the layers are synced first otherwise,
    //  when we go to display the callout, the graphic will be
    //  nil and the callout will not display!
    [self refreshLayers:[NSSet setWithArray:self.externalLayers]];
    if (MKCoordinateRegionIsValid(self->_mapRegion)) {
        [self.mapView zoomToEnvelope:AGSEnvelopeFromMKCoordinateRegionWithSpatialReference(self->_mapRegion, self.mapView.spatialReference)
                            animated:NO];
        
        // Invalidate this after everything we need is loaded since
        // we should no longer be using it.
        self->_mapRegion = MKCoordinateRegionInvalid;
    }
    
    
    [self didFinishLoadingMapView];
}

#pragma mark Property Getters
// TODO: Add the default visible envelope to the
//  maps bootstrap file.
- (MKCoordinateRegion)defaultVisibleArea
{
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin: -7916712.379879861
                                                     ymin: 5214115.052300519
                                                     xmax: -7911452.543710185
                                                     ymax: 5217411.40739323
                                         spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
    
    return MKCoordinateRegionFromAGSEnvelope(envelope);
}

// TODO: Add the default maximum envelope to the
//  maps bootstrap file.
- (MKCoordinateRegion)defaultMaximumEnvelope
{
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin: -7920689.320999366
                                                     ymin: 5211048.119330198
                                                     xmax: -7907475.602590679
                                                     ymax: 5219026.033192276
                                         spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
    
    return MKCoordinateRegionFromAGSEnvelope(envelope);
}


#pragma mark Lookup Methods
- (MGSLayerController*)layerManagerForLayer:(MGSLayer*)layer
{
    MGSLayerController *layerManager = nil;
    
    for (MGSLayerController* manager in self.externalLayerManagers) {
        if ([manager.layer isEqual:layer]) {
            layerManager = manager;
        }
    }
    
    return layerManager;
}

- (MGSLayer*)layerContainingAnnotation:(id <MGSAnnotation>)annotation
{
    id <MGSAnnotation> theAnnotation = annotation;
    
    if ([annotation respondsToSelector:@selector(annotation)]) {
        theAnnotation = [annotation performSelector:@selector(annotation)];
    }
    
    
    __block MGSLayer* myLayer = nil;
    [self.mapLayers enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(MGSLayer* layer, NSUInteger idx, BOOL* stop) {
                                         
                                         if ([layer.annotations containsObject:theAnnotation]) {
                                             myLayer = layer;
                                             (*stop) = YES;
                                         }
                                     }];
    
    return myLayer;
}

- (MGSLayer*)layerContainingGraphic:(AGSGraphic*)graphic
{
    __block MGSLayer* myLayer = nil;
    [self.mapLayers enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(MGSLayer* layer, NSUInteger idx, BOOL* stop) {
                                         MGSLayerController* manager = [self layerManagerForLayer:layer];
                                         if ([manager layerAnnotationForGraphic:graphic]) {
                                             myLayer = layer;
                                             (*stop) = YES;
                                         }
                                     }];
    
    return myLayer;
}


#pragma mark - Delegation
- (void)mapViewDidLoad:(AGSMapView*)mapView
{
    DDLogVerbose(@"basemap loaded with WKID %d", mapView.spatialReference.wkid);
    mapView.maxEnvelope = AGSEnvelopeFromMKCoordinateRegionWithSpatialReference([self defaultMaximumEnvelope], mapView.spatialReference);

    MKCoordinateRegion visibleRegion = [self defaultVisibleArea];
    [mapView zoomToEnvelope:AGSEnvelopeFromMKCoordinateRegionWithSpatialReference(visibleRegion, mapView.spatialReference)
                   animated:NO];
}

- (BOOL)mapView:(AGSMapView*)mapView shouldShowCalloutForGraphic:(AGSGraphic*)graphic
{
    MGSLayer* myLayer = [self layerContainingGraphic:graphic];
    MGSLayerController* manager = [self layerManagerForLayer:myLayer];
    id <MGSAnnotation> annotation = [[manager layerAnnotationForGraphic:graphic] annotation];
    
    if (graphic.infoTemplateDelegate == nil) {
        graphic.infoTemplateDelegate = self;
    }
    
    return [self shouldShowCalloutForAnnotation:annotation];
}

- (BOOL)mapView:(AGSMapView*)mapView shouldShowCalloutForLocationDisplay:(AGSLocationDisplay*)ld
{
    return NO;
}

- (void)mapViewWillDismissCallout:(AGSMapView*)mapView
{
    /* This space intentially left blank.
     Well, not blank but you get the idea.
     Seriously, there's nothing here.
     Stop it.
     Reading more isn't going to change anything.
     */
}

- (void)mapViewDidDismissCallout:(AGSMapView*)mapView
{
    if (self.calloutAnnotation) {
        [self didDismissCalloutForAnnotation:self.calloutAnnotation];
        self.calloutAnnotation = nil;
    }
}

- (BOOL)mapView:(AGSMapView*)mapView shouldProcessClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint
{
    return YES;
}

- (void)mapView:(AGSMapView*)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint graphics:(NSDictionary*)graphics
{
    CGPoint viewPoint = [self.mapView convertPoint:screen
                                          fromView:nil];
    
    if (self.isPresentingCallout) {
        if (CGRectContainsPoint(self.mapView.callout.frame, viewPoint) == NO) {
            [self dismissCallout];
        }
    }
    
    NSMutableArray *tappedGraphics = [NSMutableArray array];
    [graphics enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *layerGraphics, BOOL *stop) {
        [tappedGraphics addObjectsFromArray:layerGraphics];
    }];
    
    if ([tappedGraphics count]) {
        [tappedGraphics sortUsingComparator:^NSComparisonResult(AGSGraphic *graphic1, AGSGraphic *graphic2) {
            MGSLayer *layer1 = [self layerContainingGraphic:graphic1];
            NSUInteger index1 = [self.externalLayers indexOfObject:layer1];
            
            MGSLayer *layer2 = [self layerContainingGraphic:graphic2];
            NSUInteger index2 = [self.externalLayers indexOfObject:layer2];
            
            if (index1 < index2) {
                return NSOrderedDescending;
            } else if (index1 > index2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }];
        
        [tappedGraphics enumerateObjectsUsingBlock:^(AGSGraphic *graphic, NSUInteger idx, BOOL *stop) {
            BOOL showCallout = [self mapView:mapView
                 shouldShowCalloutForGraphic:graphic];
            
            if (showCallout) {
                MGSLayer *layer = [self layerContainingGraphic:graphic];
                MGSLayerController *layerManager = [self layerManagerForLayer:layer];
                id<MGSAnnotation> annotation = [layerManager layerAnnotationForGraphic:graphic].annotation;
                
                [self showCalloutForAnnotation:annotation];
                (*stop) = YES;
            }
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(mapView:didReceiveTapAtCoordinate:screenPoint:)]) {
        [self.delegate mapView:self
     didReceiveTapAtCoordinate:CLLocationCoordinate2DFromAGSPoint(mappoint)
                   screenPoint:screen];
    }
}

- (void)didClickAccessoryButtonForCallout:(AGSCallout*)callout
{
    if (self.calloutAnnotation) {
        [self calloutDidReceiveTapForAnnotation:self.calloutAnnotation];
    }
}

- (void)layer:(AGSLayer*)loadedLayer didInitializeSpatialReferenceStatus:(BOOL)srStatusValid
{
    if (srStatusValid) {
        DDLogVerbose(@"initialized spatial reference for layer '%@' to %d", loadedLayer.name, [loadedLayer.spatialReference wkid]);
    } else {
        DDLogError(@"failed to initialize spatial reference for layer '%@'", loadedLayer.name);
        [self.baseLayers removeObjectForKey:loadedLayer.name];
        [self.mapView removeMapLayer:loadedLayer];
    }

    // Perform the coreLayersLoaded checking here since we don't want to add any of the
    // user layers until we actually have a spatial reference to work with.
    if (self.baseLayers[loadedLayer.name]) {
        if (self.isBaseLayersLoaded == NO) {
            __block BOOL layersLoaded = YES;
            [self.baseLayers enumerateKeysAndObjectsUsingBlock:^(NSString* name, AGSLayer* layer, BOOL* stop) {
                layersLoaded = (layersLoaded && layer.spatialReference);
            }];


            // Check again after we iterate through everything to make sure the state
            // hasn't changed now that we have another layer loaded
            if (layersLoaded) {
                [self baseLayersDidFinishLoading];
            }
        }
    }
}

- (void)layer:(AGSLayer*)layer didFailToLoadWithError:(NSError*)error
{
    DDLogError(@"failed to load layer '%@': %@", layer.name, [error localizedDescription]);
    [self.baseLayers removeObjectForKey:layer.name];
    [self.mapView removeMapLayer:layer];
}

- (void)locationDisplayDataSource:(id <AGSLocationDisplayDataSource>)dataSource
                 didFailWithError:(NSError*)error
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
            didUpdateWithLocation:(AGSLocation*)location
{
    CLLocation* clLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DFromAGSPoint(location.point)
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

#pragma mark --AGSInfoTemplateDelegate
- (UIView*)customViewForGraphic:(AGSGraphic *)graphic
                    screenPoint:(CGPoint)screen
                       mapPoint:(AGSPoint *)mapPoint
{
    MGSLayer* myLayer = [self layerContainingGraphic:graphic];
    MGSLayerController* manager = [self layerManagerForLayer:myLayer];
    id <MGSAnnotation> annotation = [[manager layerAnnotationForGraphic:graphic] annotation];
    
    return [self calloutViewForAnnotation:annotation];
}

#pragma mark --MGSLayerManagerDelegate
- (void)layerManagerDidSynchronizeAnnotations:(MGSLayerController*)layerManager
{
    if (self.pendingCalloutAnnotation) {
        if ([layerManager.layer.annotations containsObject:self.pendingCalloutAnnotation]) {
            [self showCalloutForAnnotation:self.pendingCalloutAnnotation];
            self.pendingCalloutAnnotation = nil;
        }
    }
}
@end
