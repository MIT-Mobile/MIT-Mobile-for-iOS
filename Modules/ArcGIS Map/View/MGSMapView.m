#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"
#import "MGSMapView+Delegation.h"

#import "MGSUtility.h"
#import "MGSGeometry.h"
#import "MGSLayer.h"
#import "MGSCalloutView.h"

#import "MobileRequestOperation.h"
#import "MGSLayerManager.h"
#import "MGSSafeAnnotation.h"
#import "MGSLayerAnnotation.h"


@interface MGSMapView () <AGSMapViewTouchDelegate, AGSCalloutDelegate, AGSMapViewLayerDelegate, AGSMapViewCalloutDelegate, AGSLayerDelegate, AGSLocationDisplayDataSourceDelegate, AGSInfoTemplateDelegate, MGSLayerManagerDelegate>
#pragma mark - Basemap Management (Declaration)
@property(nonatomic,assign) BOOL baseLayersLoaded;
@property(nonatomic,strong) NSMutableDictionary* baseLayers;
@property(nonatomic,strong) NSDictionary* baseMapGroups;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property(nonatomic, strong) NSMutableArray* externalLayers;
@property(nonatomic, strong) NSMutableSet* externalLayerManagers;

// Used when getting/setting the map region before the map layer loads
// If the map is not loaded, the cached region will contain the last
// region that was added to the operation queue. If no region was set and
// the map layer
@property(nonatomic) BOOL initialMapRegionWasSet;
@property(nonatomic) MKCoordinateRegion initialRegion;
#pragma mark -

@property(nonatomic, weak) AGSMapView* mapView;
@property(nonatomic, strong) MGSLayer* defaultLayer;
@property(nonatomic, strong) id <MGSAnnotation> calloutAnnotation;
@property(nonatomic, strong) id <MGSAnnotation> pendingCalloutAnnotation;

- (void)baseLayersDidFinishLoading;
- (AGSEnvelope*)defaultVisibleArea;
- (AGSEnvelope*)defaultMaximumEnvelope;
- (MGSLayerManager*)layerManagerForLayer:(MGSLayer*)layer;

#pragma mark Delegation Helpers
- (BOOL)shouldShowCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation;
- (void)calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation;
- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)didDismissCalloutForAnnotation:(id<MGSAnnotation>)annotation;

- (void)didFinishLoadingMapView;
- (void)willAddLayer:(MGSLayer *)layer;
- (void)didAddLayer:(MGSLayer *)layer;
- (void)willRemoveLayer:(MGSLayer *)layer;
- (void)didRemoveLayer:(MGSLayer *)layer;

- (void)userLocationDidUpdate:(CLLocation*)location;
- (void)userLocationUpdateFailedWithError:(NSError*)error;
@end

@implementation MGSMapView
@dynamic mapSets;
@dynamic showUserLocation;

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

- (void)commonInit
{
    self.baseLayersLoaded = NO;
    self.externalLayers = [NSMutableArray array];
    self.externalLayerManagers = [NSMutableSet set];

    self.initialMapRegionWasSet = NO;

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
            view.maxEnvelope = [self defaultMaximumEnvelope];
            
            
            [self addSubview:view];
            self.mapView = view;
        }
        
        
        MobileRequestOperation* operation = [MobileRequestOperation operationWithModule:@"map"
                                                                                command:@"bootstrap"
                                                                             parameters:nil];
        [operation setCompleteBlock:^(MobileRequestOperation* blockOperation, id content, NSString* contentType, NSError* error) {
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
        
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    
    self.defaultLayer = [[MGSLayer alloc] initWithName:@"Default"];
    [self addLayer:self.defaultLayer];
}

- (AGSEnvelope*)defaultVisibleArea
{
    return [AGSEnvelope envelopeWithXmin:-7916712.379879861
                                    ymin:5214115.052300519
                                    xmax:-7911452.543710185
                                    ymax:5217411.40739323
                        spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
}

- (AGSEnvelope*)defaultMaximumEnvelope
{
    return [AGSEnvelope envelopeWithXmin:-7920689.320999366
                                    ymin:5211048.119330198
                                    xmax:-7907475.602590679
                                    ymax:5219026.033192276
                        spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
}

#pragma mark - Basemap Management
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

#pragma mark - Dynamic Properties
- (void)setShowUserLocation:(BOOL)showUserLocation
{
    if (showUserLocation) {
        [self.mapView.locationDisplay startDataSource];
        self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeOff;
        self.mapView.locationDisplay.dataSource.delegate = self;
    } else {
        [self.mapView.locationDisplay stopDataSource];
    }

}

- (BOOL)showUserLocation
{
    return self.mapView.locationDisplay.dataSource && self.mapView.locationDisplay.isDataSourceStarted;
}

- (NSArray*)mapLayers
{
    return [NSArray arrayWithArray:self.externalLayers];
}

- (BOOL)isPresentingCallout
{
    return (self.calloutAnnotation && self.mapView.callout.representedObject);
}

#pragma mark - Layer Management
- (MGSLayerManager*)layerManagerForLayer:(MGSLayer*)layer
{
    MGSLayerManager *layerManager = nil;
    
    for (MGSLayerManager* manager in self.externalLayerManagers) {
        if ([manager.layer isEqual:layer]) {
            layerManager = manager;
        }
    }

    return layerManager;
}

#pragma mark - Add/Insert Layers
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
    MGSLayerManager* layerManager = [self layerManagerForLayer:newLayer];

    if ([self.externalLayers containsObject:newLayer] == NO) {
        if (layerManager == nil) {
            layerManager = [[MGSLayerManager alloc] initWithLayer:newLayer];
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
    if (self.baseLayersLoaded) {
        [self syncLayers:@[newLayer]];
    }
}

#pragma mark - Remove Layers
- (void)removeLayer:(MGSLayer*)layer
{
    [self removeLayer:layer
  shoulNotifyDelegate:YES];
}

- (void)removeLayer:(MGSLayer*)layer
shoulNotifyDelegate:(BOOL)notifyDelegate
{
    MGSLayerManager* layerManager = [self layerManagerForLayer:layer];

    if (layerManager == nil) {
        DDLogError(@"external layers out of sync during removal of '%@'", layer.name);
    }

    if (layer) {
        if (notifyDelegate) {
            [self willRemoveLayer:layer];
        }

        [self.externalLayers removeObject:layer];
        [self.externalLayerManagers removeObject:layerManager];

        if (layerManager.graphicsLayer) {
            [self.mapView removeMapLayer:layerManager.graphicsLayer];
        }

        if (notifyDelegate) {
            [self didRemoveLayer:layer];
        }

        [self moveLayer:self.defaultLayer
                toIndex:[self.externalLayers count]];
    }
}

#pragma mark - Layer Visibility/Reorganization
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

- (BOOL)isLayerHidden:(MGSLayer*)layer
{
    MGSLayerManager* manager = [self layerManagerForLayer:layer];
    return (manager.graphicsLayer.isVisible);
}

- (void)setHidden:(BOOL)hidden
         forLayer:(MGSLayer*)layer
{
    MGSLayerManager* manager = [self layerManagerForLayer:layer];
    manager.graphicsLayer.visible = !hidden;
}

- (void)refreshLayer:(MGSLayer*)layer {

}
#pragma mark -
#pragma mark - Map Region Mutators
- (MGSZoomLevel)zoomLevel
{
    return MGSZoomLevelForMKCoordinateSpan(self.mapRegion.span);
}

- (void)setZoomLevel:(MGSZoomLevel)zoomLevel
{
    MKCoordinateRegion region = self.mapRegion;
    region.span = MKCoordinateSpanForMGSZoomLevel(zoomLevel);

    self.mapRegion = region;
}

- (MKCoordinateRegion)mapRegion
{
    if (self.initialMapRegionWasSet) {
        return self.initialRegion;
    }

    AGSEnvelope* regionEnvelope = nil;

    if (self.baseLayersLoaded) {
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

- (void)setMapRegion:(MKCoordinateRegion)mapRegion
{
    [self setMapRegion:mapRegion
              animated:NO];
}

- (void)setMapRegion:(MKCoordinateRegion)mapRegion animated:(BOOL)animated
{
    BOOL mapRegionIsValid = ((CLLocationCoordinate2DIsValid(mapRegion.center)) &&
                             (mapRegion.span.latitudeDelta > 0) &&
                             (mapRegion.span.longitudeDelta > 0));

    if (mapRegionIsValid == NO) {
        // If the region is invalid, don't change anything
        DDLogError(@"attempting to set a empty or invalid region.");
    } else if (self.mapView.spatialReference) {
        AGSMutableEnvelope* envelope = [[AGSMutableEnvelope alloc] initWithSpatialReference:[AGSSpatialReference wgs84SpatialReference]];

        double offsetX = (mapRegion.span.longitudeDelta / 2.0);
        double offsetY = (mapRegion.span.latitudeDelta / 2.0);

        [envelope updateWithXmin:mapRegion.center.longitude - offsetX
                            ymin:mapRegion.center.latitude - offsetY
                            xmax:mapRegion.center.longitude + offsetX
                            ymax:mapRegion.center.latitude + offsetY];

        AGSGeometry* projectedGeometry = envelope;
        if ([envelope.spatialReference isEqualToSpatialReference:self.mapView.spatialReference] == NO) {
            projectedGeometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:envelope
                                                                        toSpatialReference:self.mapView.spatialReference];

            if ([projectedGeometry isEmpty] || ([projectedGeometry isValid] == NO)) {
                projectedGeometry = [self defaultVisibleArea];
            }
        }

        animated = self.baseLayersLoaded && animated;
        [self.mapView zoomToGeometry:projectedGeometry
                         withPadding:0.0
                            animated:animated];
    } else {
        self.initialMapRegionWasSet = YES;
        self.initialRegion = mapRegion;
    }
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self centerAtCoordinate:coordinate
                    animated:YES];
}

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate
                  animated:(BOOL)animated
{
    MKCoordinateSpan span = MKCoordinateSpanForMGSZoomLevel(self.zoomLevel);

    [self setMapRegion:MKCoordinateRegionMake(coordinate, span)
              animated:animated];
}


#pragma mark -
- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate
{
    DDLogVerbose(@"Spatial Reference: %@", self.mapView.spatialReference);

    if (self.baseLayersLoaded) {
        return [self.mapView toScreenPoint:AGSPointFromCLLocationCoordinate2DInSpatialReference(coordinate, self.mapView.spatialReference)];
    } else {
        return CGPointZero;
    }
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    if (self.baseLayersLoaded) {
        if (self.calloutAnnotation) {
            [self dismissCallout];
        }

        if ([self shouldShowCalloutForAnnotation:annotation]) {
            MGSLayer* layer = [self layerContainingAnnotation:annotation];
            MGSLayerManager* manager = [self layerManagerForLayer:layer];
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
            [self.mapView centerAtPoint:graphic.geometry.envelope.center
                               animated:YES];
            
            self.mapView.callout.delegate = self;
            [self.mapView.callout showCalloutAtPoint:nil
                                          forGraphic:graphic
                                            animated:YES];
            [self didShowCalloutForAnnotation:annotation];
        }
    } else {
        // This will be used once all of the core layers have loaded.
        // An important note: the way this will be used bypasses the normal
        // showCalloutForAnnotation:/dismissCallout methods. See the
        // coreLayersDidFinishLoading method for more details
        self.pendingCalloutAnnotation = annotation;
    }
}

- (void)dismissCallout
{
    [self.mapView.callout dismiss];
    [self didDismissCalloutForAnnotation:self.calloutAnnotation];
    self.calloutAnnotation = nil;
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
                                         MGSLayerManager* manager = [self layerManagerForLayer:layer];
                                         if ([manager layerAnnotationForGraphic:graphic]) {
                                             myLayer = layer;
                                             (*stop) = YES;
                                         }
                                     }];

    return myLayer;
}

- (void)syncLayers:(NSArray*)layers {
    if (self.baseLayersLoaded) {
        NSArray *sortedArrays = [layers sortedArrayUsingComparator:^NSComparisonResult(MGSLayer *layer1, MGSLayer *layer2) {
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
                MGSLayerManager *manager = [self layerManagerForLayer:layer];
                manager.spatialReference = self.mapView.spatialReference;
                
                AGSGraphicsLayer *graphicsLayer = manager.graphicsLayer;
                NSUInteger agsLayerIndex = [self.baseLayers count] + layerIndex;
                
                if ([self.mapView.mapLayers containsObject:graphicsLayer] == NO) {
                    graphicsLayer.delegate = self;
                    [self.mapView insertMapLayer:graphicsLayer
                                        withName:layer.name
                                         atIndex:agsLayerIndex];
                }
                
                [manager syncAnnotations];
            }
        }];
    }
}

- (void)baseLayersDidFinishLoading
{
    // Make sure the layers are synced first otherwise,
    //  when we go to display the callout, the graphic will be
    //  nil and the callout will not display!
    [self syncLayers:self.externalLayers];
    [self didFinishLoadingMapView];
}


#pragma mark Delegation Helpers
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
    
    [self.mapView centerAtPoint:self.mapView.callout.mapLocation
                       animated:YES];
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
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(mapView:calloutDidReceiveTapForAnnotation:)]) {
            [self.delegate mapView:self calloutDidReceiveTapForAnnotation:annotation];
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

#pragma mark Layer Mutation
- (void)didFinishLoadingMapView
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(didFinishLoadingMapView:)]) {
            [self.delegate didFinishLoadingMapView:self];
        }
    }];
}

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
@end

#pragma mark - Delegation
@implementation MGSMapView (Delegation)
- (void)mapViewDidLoad:(AGSMapView*)mapView
{
    DDLogVerbose(@"basemap loaded with WKID %d", mapView.spatialReference.wkid);

    AGSEnvelope* maxEnvelope = (AGSEnvelope*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:[self defaultMaximumEnvelope]
                                                                                      toSpatialReference:mapView.spatialReference];
    mapView.maxEnvelope = maxEnvelope;

    if (self.initialMapRegionWasSet) {
        [self setMapRegion:self.initialRegion
                  animated:NO];
    } else {
        AGSEnvelope* visibleEnvelope = (AGSEnvelope*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:[self defaultVisibleArea]
                                                                                              toSpatialReference:[AGSSpatialReference wgs84SpatialReference]];

        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DFromAGSPoint(visibleEnvelope.center),
                                                           MKCoordinateSpanMake(fabs(visibleEnvelope.ymax - visibleEnvelope.ymin),
                                                                                fabs(visibleEnvelope.xmax - visibleEnvelope.xmin)));
        [self setMapRegion:region
                  animated:NO];
    }
}

- (BOOL)mapView:(AGSMapView*)mapView shouldShowCalloutForGraphic:(AGSGraphic*)graphic
{
    MGSLayer* myLayer = [self layerContainingGraphic:graphic];
    MGSLayerManager* manager = [self layerManagerForLayer:myLayer];
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
                MGSLayerManager *layerManager = [self layerManagerForLayer:layer];
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

- (void)mapView:(AGSMapView*)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint graphics:(NSDictionary*)graphics
{

}

- (void)mapView:(AGSMapView*)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint graphics:(NSDictionary*)graphics
{

}

- (void)mapView:(AGSMapView*)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint graphics:(NSDictionary*)graphics
{

}

- (void)mapViewDidCancelTapAndHold:(AGSMapView*)mapView
{

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
        if (self.baseLayersLoaded == NO) {
            __block BOOL layersLoaded = YES;
            [self.baseLayers enumerateKeysAndObjectsUsingBlock:^(NSString* name, AGSLayer* layer, BOOL* stop) {
                layersLoaded = (layersLoaded && layer.spatialReference);
            }];


            // Check again after we iterate through everything to make sure the state
            // hasn't changed now that we have another layer loaded
            if (layersLoaded) {
                self.baseLayersLoaded = YES;
                [self baseLayersDidFinishLoading];
            }
        }
    }/* else if (self.pendingCalloutAnnotation) {
        [self.externalLayers enumerateObjectsUsingBlock:^(MGSLayer *layer, NSUInteger idx, BOOL *stop) {
            MGSLayerManager *layerManager = [self layerManagerForLayer:layer];
            MGSLayerAnnotation *layerAnnotation = [layerManager layerAnnotationForAnnotation:self.pendingCalloutAnnotation];
            if (layerAnnotation && layerAnnotation.graphic) {
                (*stop) = YES;
                [self showCalloutForAnnotation:layerAnnotation.annotation];
                self.pendingCalloutAnnotation = nil;
            }
        }];
    }
    */
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

#pragma mark AGSInfoTemplateDelegate
- (UIView*)customViewForGraphic:(AGSGraphic *)graphic
                    screenPoint:(CGPoint)screen
                       mapPoint:(AGSPoint *)mapPoint
{
    MGSLayer* myLayer = [self layerContainingGraphic:graphic];
    MGSLayerManager* manager = [self layerManagerForLayer:myLayer];
    id <MGSAnnotation> annotation = [[manager layerAnnotationForGraphic:graphic] annotation];
    
    return [self calloutViewForAnnotation:annotation];
}

#pragma mark MGSLayerManagerDelegate
- (void)layerManagerDidSynchronizeAnnotations:(MGSLayerManager*)layerManager
{
    if (self.pendingCalloutAnnotation) {
        if ([layerManager.layer.annotations containsObject:self.pendingCalloutAnnotation]) {
            [self showCalloutForAnnotation:self.pendingCalloutAnnotation];
            self.pendingCalloutAnnotation = nil;
        }
    }
}
@end
