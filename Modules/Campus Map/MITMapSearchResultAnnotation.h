
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MITMobileWebAPI.h"

@class MITMapPlace;

@interface MITMapSearchResultAnnotation : NSObject <MKAnnotation>
@property (nonatomic,strong) MITMapPlace *place;
@property BOOL bookmark;

- (id)initWithPlace:(MITMapPlace*)place;
@end
