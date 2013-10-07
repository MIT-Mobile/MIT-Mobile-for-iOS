#import <Foundation/Foundation.h>
#import "MGSAnnotation.h"

@interface MGSSimpleAnnotation : NSObject <MGSAnnotation,NSCopying>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, strong) UIImage *calloutImage;

@property (nonatomic, strong) UIImage *markerImage;
@property (nonatomic) MGSMarkerOptions markerOptions;

@property (nonatomic) MGSAnnotationType annotationType;

// Used only when annotationType is a polygon or polyline
@property (nonatomic) NSArray* points;
@property (nonatomic) UIColor* strokeColor;
@property (nonatomic) UIColor* fillColor;
@property (nonatomic) CGFloat lineWidth;

@property (nonatomic, strong) id<NSObject> representedObject;

- (id)init;
- (id)initWithAnnotationType:(MGSAnnotationType)type;

@end
