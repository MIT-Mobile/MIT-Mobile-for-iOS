#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSMapViewDelegate.h"

@class MGSMapCoordinate;
@class MGSMapAnnotation;
@class MGSMapQuery;
@class MGSMapLayer;
@class MGSQueryLayer;

@protocol MGSAnnotation;

@interface MGSMapView : UIView
#pragma mark - Basemap Management
@property (nonatomic, strong) NSString *activeMapSet;
@property (nonatomic, strong, readonly) NSSet *mapSets;

@property (nonatomic, readonly) NSArray *allLayers;
@property (nonatomic, readonly) NSArray *visibleLayers;

@property (nonatomic) BOOL showUserLocation;
@property (nonatomic,assign) id<MGSMapViewDelegate> mapViewDelegate;
@property (nonatomic,readonly,strong) MGSMapLayer *defaultLayer;
@property (nonatomic) MKCoordinateRegion mapRegion;

#pragma mark - Layer Management
- (NSString*)nameForMapSetWithIdentifier:(NSString*)basemapIdentifier;

- (void)addLayer:(MGSMapLayer*)layer withIdentifier:(NSString*)layerIdentifier;
- (void)insertLayer:(MGSMapLayer*)layer atIndex:(NSUInteger)layerIndex withIdentifier:(NSString*)layerIdentifier; 
- (MGSMapLayer*)layerWithIdentifier:(NSString*)layerIdentifier;
- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier;
- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier;

- (void)centerOnAnnotation:(id<MGSAnnotation>)annotation;
- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)centerAtCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;
- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

- (BOOL)isLayerHidden:(NSString*)layerIdentifier;
- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString*)layerIdentifier;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSAnnotation>)annotation;
- (void)showCalloutWithView:(UIView*)view
              forAnnotation:(id<MGSAnnotation>)annotation;
- (void)hideCallout;
- (BOOL)isPresentingCalloutForAnnotation:(id<MGSAnnotation>)annotation;

@end
