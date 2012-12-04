#import "MGSMapLayer.h"
#import <ArcGIS/ArcGIS.h>

@class MGSMapView;

@interface MGSMapLayer ()
@property (weak) MGSMapView *mapView;
@property (weak) UIView<AGSLayerView> *graphicsView;
@property (nonatomic,strong) AGSGraphicsLayer *graphicsLayer;
@property (strong) AGSRenderer *renderer;
@property (nonatomic,readonly) BOOL hasGraphicsLayer;
@property (nonatomic,strong) NSMutableArray *layerAnnotations;

- (void)loadGraphicsLayer;
@end