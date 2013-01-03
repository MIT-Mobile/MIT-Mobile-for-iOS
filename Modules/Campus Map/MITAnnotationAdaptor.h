#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "MITMapAnnotationView.h"
#import "MGSSimpleAnnotation.h"


@interface MITAnnotationAdaptor : MGSSimpleAnnotation
@property (nonatomic,strong) id<MKAnnotation> mkAnnotation;
@property (nonatomic,strong) MITMapAnnotationView *legacyAnnotationView;

- (id)initWithMKAnnotation:(id<MKAnnotation>)annotation;
@end