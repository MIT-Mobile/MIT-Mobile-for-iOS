#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MGSAnnotation.h"

@interface MGSSafeAnnotation : NSObject <MGSAnnotation>
@property (nonatomic,readonly,strong) id<MGSAnnotation> annotation;

@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic,readonly) BOOL canShowCallout;
@property (nonatomic,readonly, copy) NSString *title;
@property (nonatomic,readonly, copy) NSString *detail;
@property (nonatomic,readonly, strong) UIImage *calloutImage;
@property (nonatomic,readonly, strong) UIImage *markerImage;

@property (nonatomic,readonly, strong) UIView *calloutView;


@property (nonatomic,readonly,assign) MGSAnnotationType annotationType;

// Used only when annotationType is a polygon or polyline
@property (nonatomic,readonly,strong) NSArray* points;
@property (nonatomic,readonly,strong) UIColor* strokeColor;
@property (nonatomic,readonly,strong) UIColor* fillColor;
@property (nonatomic,readonly) CGFloat lineWidth;

@property (nonatomic,readonly, strong) id<NSObject> userData;

- (id)init;
- (id)initWithAnnotation:(id<MGSAnnotation>)annotation;
@end
