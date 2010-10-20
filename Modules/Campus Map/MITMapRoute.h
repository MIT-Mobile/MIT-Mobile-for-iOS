
#import <UIKit/UIKit.h>


@protocol MITMapRoute

@required

// array of CLLocations making up the path of this route
-(NSArray*) pathLocations;

// array of MKAnnotations that are to be included with this route
-(NSArray*) annotations;

// color of the route line to be rendered
-(UIColor*) lineColor;

// width of the route line to be rendered
-(CGFloat) lineWidth;

@end
