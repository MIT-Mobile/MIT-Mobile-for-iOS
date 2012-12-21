#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSAnnotation.h"

@class MGSLayer;

@interface MGSLayerAnnotation : NSObject <MGSAnnotation>
@property (weak) MGSLayer *layer;
@property (weak) AGSLayer *agsLayer;

@property (nonatomic,strong) id<MGSAnnotation> annotation;
@property (nonatomic,strong) AGSGraphic *graphic;
@property (strong) NSDictionary *attributes;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// MGSAnnotation protcol
@property (nonatomic, readonly, assign) BOOL canShowCallout;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *detail;
@property (nonatomic, readonly, strong) UIImage *image;

@property (nonatomic, readonly, strong) UIView *annotationView;
@property (nonatomic, readonly, strong) UIView *calloutView;
@property (nonatomic, readonly) MGSAnnotationType annotationType;

@property (nonatomic, readonly, strong) id<NSObject> userData;

- (id)initWithAnnotation:(id<MGSAnnotation>)annotation
                 graphic:(AGSGraphic*)graphic;
@end
