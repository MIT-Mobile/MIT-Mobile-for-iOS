#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSMapViewDelegate.h"
#import "MGSGeometry.h"

@class MGSMapCoordinate;
@class MGSLayerManager;
@class MGSMapAnnotation;
@class MGSMapQuery;
@class MGSLayer;
@class MGSQueryLayer;

@protocol MGSAnnotation;

@interface MGSMapView : UIView
#pragma mark - Basemap Management
@property (nonatomic, strong) NSString *activeMapSet;
@property (nonatomic, strong, readonly) NSSet *mapSets;

@property (nonatomic, readonly) NSArray *mapLayers;

@property (nonatomic) BOOL showUserLocation;
@property (nonatomic,assign) id<MGSMapViewDelegate> delegate;
@property (nonatomic,readonly,strong) MGSLayer *defaultLayer;
@property (nonatomic) MKCoordinateRegion mapRegion;
@property (nonatomic,readonly) BOOL isPresentingCallout;
@property (nonatomic,readonly) id<MGSAnnotation> calloutAnnotation;
@property (nonatomic) MGSZoomLevel zoomLevel;

#pragma mark - Layer Management
- (NSString*)nameForMapSetWithIdentifier:(NSString*)basemapIdentifier;

- (void)addLayer:(MGSLayer*)layer;
- (void)removeLayer:(MGSLayer*)layer;
- (void)insertLayer:(MGSLayer*)layer
        behindLayer:(MGSLayer*)foregroundLayer;
- (MGSLayerManager*)layerManagerForLayer:(MGSLayer*)layer;

- (MGSLayer*)layerContainingAnnotation:(id<MGSAnnotation>)annotation;

- (void)refreshLayer:(MGSLayer*)layer;

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate
                  animated:(BOOL)animated;
- (void)setMapRegion:(MKCoordinateRegion)mapRegion
            animated:(BOOL)animated;

- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

- (BOOL)isLayerHidden:(MGSLayer*)layerIdentifier;
- (void)setHidden:(BOOL)hidden
         forLayer:(MGSLayer*)layer;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)dismissCallout;
@end
