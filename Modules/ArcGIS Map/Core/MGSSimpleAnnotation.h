#import <Foundation/Foundation.h>
#import "MGSAnnotation.h"

// This class is a wrapper for an object which implements
// all of the methods and property in the MGSAnnotation protocol
// and wraps them so that even the optional methods
// should return a sane value and not die
@interface MGSSimpleAnnotation : NSObject <MGSAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, strong) UIImage *calloutImage;
@property (nonatomic, strong) UIImage *markerImage;

@property (nonatomic) MGSAnnotationType annotationType;

// Used only when annotationType is a polygon or polyline
@property (nonatomic) NSArray* points;
@property (nonatomic) UIColor* strokeColor;
@property (nonatomic) UIColor* fillColor;
@property (nonatomic) CGFloat lineWidth;

@property (nonatomic, strong) id<NSObject> userData;
@end
