#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "MITMapAnnotationView.h"

@class MGSMarker;

@interface MITAnnotationAdaptor : NSObject
@property (nonatomic,strong) id<MKAnnotation> annotation;
@property (nonatomic,strong) MITMapAnnotationView *annotationView;
@property (nonatomic,strong) MGSMarker *cachedMarker;

- (id)initWithMKAnnotation:(id<MKAnnotation>)annotation;
@end