#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSMapViewDelegate.h"

@class MGSMapCoordinate;
@class MGSMapAnnotation;
@class MGSMapQuery;
@class MGSLayer;
@class MGSQueryLayer;

@protocol MGSAnnotation;

typedef CGFloat MGSZoomLevel;

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
@property (nonatomic) CGFloat zoomLevel;

+ (MGSZoomLevel)zoomLevelForMKCoordinateSpan:(MKCoordinateSpan)span;
+ (MKCoordinateSpan)coordinateSpanForZoomLevel:(MGSZoomLevel)zoomLevel;

#pragma mark - Layer Management
- (NSString*)nameForMapSetWithIdentifier:(NSString*)basemapIdentifier;

- (void)addLayer:(MGSLayer*)layer;
- (void)insertLayer:(MGSLayer*)layer
            atIndex:(NSUInteger)layerIndex;

- (void)insertLayer:(MGSLayer*)layer
        behindLayer:(MGSLayer*)foregroundLayer;

- (MGSLayer*)layerContainingAnnotation:(id<MGSAnnotation>)annotation;
- (BOOL)containsLayer:(MGSLayer*)layer;
- (void)removeLayer:(MGSLayer*)layer;

- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;
- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

- (BOOL)isLayerHidden:(MGSLayer*)layerIdentifier;
- (void)setHidden:(BOOL)hidden forLayer:(MGSLayer*)layer;
- (void)setMapRegion:(MKCoordinateRegion)mapRegion animated:(BOOL)animated;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)hideCallout;
@end
