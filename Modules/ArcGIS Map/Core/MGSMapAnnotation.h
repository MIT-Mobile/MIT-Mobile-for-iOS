#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MGSMapCoordinate;
@class MGSMarker;
@class MGSMapAnnotation;
@class MGSMapLayer;


@interface MGSMapAnnotation : NSObject <NSCopying>
@property (weak,readonly) MGSMapLayer *layer;
@property (strong) MGSMapCoordinate *coordinate;
@property (strong) MGSMarker *marker;

@property (strong) NSString *title;
@property (strong) NSString *detail;
@property (strong) UIImage *image;
@property (strong) id userData;
@property (strong) NSDictionary *attributes;

- (id)initWithTitle:(NSString*)title
         detailText:(NSString*)detail
       atCoordinate:(MGSMapCoordinate*)coordinate;
@end
