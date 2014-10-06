#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MITMapDelegateInterceptor : NSObject <MKMapViewDelegate>

@property (nonatomic, strong) id endOfLineDelegate;
@property (nonatomic, strong) id middleManDelegate;

@end