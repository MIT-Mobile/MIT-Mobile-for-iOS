#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSMapViewDelegate.h"
#import "MGSGeometry.h"

@class MGSMapCoordinate;
@class MGSLayerController;
@class MGSMapAnnotation;
@class MGSMapQuery;
@class MGSLayer;
@class MGSQueryLayer;

@protocol MGSAnnotation;

@interface MGSMapView : UIView
#pragma mark - Properties
@property (nonatomic,assign) id<MGSMapViewDelegate> delegate;

#pragma mark Base Map Set Management
@property (nonatomic, strong) NSString *activeMapSet;
@property (nonatomic, readonly, strong) NSSet *mapSets;

#pragma mark Visible Region
@property (nonatomic) MKCoordinateRegion mapRegion;
@property (nonatomic) MGSZoomLevel zoomLevel;
@property (nonatomic) CLLocationCoordinate2D centerCoordinate;

#pragma mark Layer Management
@property (nonatomic,readonly,strong) MGSLayer *defaultLayer;
@property (nonatomic, readonly) NSArray *mapLayers;

#pragma mark Callout Handling
@property (nonatomic,readonly) BOOL isPresentingCallout;
@property (nonatomic,readonly,strong) id<MGSAnnotation> calloutAnnotation;

#pragma mark Location Updates
@property (nonatomic) BOOL showUserLocation;
@property (nonatomic) BOOL trackUserLocation;


#pragma mark - Methods
#pragma mark Initialization
- (id)init;
- (id)initWithCoder:(NSCoder*)aDecoder;
- (id)initWithFrame:(CGRect)frame;


#pragma mark Base Map Set Management
- (NSString*)nameForMapSetWithIdentifier:(NSString*)mapSetIdentifier;
- (NSSet*)mapSets;
- (void)setActiveMapSet:(NSString*)mapSetName;


#pragma mark Visible Region
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coordinate
                   animated:(BOOL)animated;
- (void)setMapRegion:(MKCoordinateRegion)mapRegion
            animated:(BOOL)animated;
- (void)setZoomLevel:(MGSZoomLevel)zoomLevel
            animated:(BOOL)animated;

#pragma mark Misc
- (CGPoint)screenPointForCoordinate:(CLLocationCoordinate2D)coordinate;

#pragma mark Layer Management
- (NSArray*)mapLayers;
- (void)refreshLayers:(NSSet*)layers;

- (BOOL)isLayerHidden:(MGSLayer*)layer;
- (void)setHidden:(BOOL)hidden
         forLayer:(MGSLayer*)layer;

#pragma mark --Adding Layers
- (void)addLayer:(MGSLayer*)newLayer;
- (void)insertLayer:(MGSLayer*)layer
        behindLayer:(MGSLayer*)foregroundLayer;
- (void)insertLayer:(MGSLayer*)newLayer
            atIndex:(NSUInteger)index;
- (void)insertLayer:(MGSLayer*)newLayer
            atIndex:(NSUInteger)index
shouldNotifyDelegate:(BOOL)notifyDelegate;


#pragma mark --Removing Layers
- (void)removeLayer:(MGSLayer*)layer;
- (void)removeLayer:(MGSLayer*)layer
shoulNotifyDelegate:(BOOL)notifyDelegate;

#pragma mark --Layer Reorganization
- (void)moveLayer:(MGSLayer*)layer
          toIndex:(NSUInteger)newIndex;

#pragma mark Callout Handling
- (BOOL)isPresentingCallout;
- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)showCalloutForAnnotation:(id <MGSAnnotation>)annotation
                        animated:(BOOL)animated;
- (void)dismissCallout;

#pragma mark Delegation
#pragma mark --Map State
- (void)didFinishLoadingMapView;

#pragma mark --Layer Mutation
- (void)willAddLayer:(MGSLayer*)layer;
- (void)didAddLayer:(MGSLayer*)layer;
- (void)willRemoveLayer:(MGSLayer*)layer;
- (void)didRemoveLayer:(MGSLayer*)layer;


#pragma mark --Callout
- (BOOL)shouldShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)didShowCalloutForAnnotation:(id <MGSAnnotation>)annotation;
- (void)didDismissCalloutForAnnotation:(id <MGSAnnotation>)annotation;

- (UIView*)calloutViewForAnnotation:(id <MGSAnnotation>)annotation;
- (void)calloutDidReceiveTapForAnnotation:(id <MGSAnnotation>)annotation;


#pragma mark --Location Updates
- (void)userLocationDidUpdate:(CLLocation*)location;
- (void)userLocationUpdateFailedWithError:(NSError*)error;

@end
