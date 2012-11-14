#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    MGSMarkerStylePin = 0,
    MGSMarkerStyleSquare,
    MGSMarkerStyleCircle,
    MGSMarkerStyleHighlight,
    MGSMarkerStyleIcon,
    MGSMarkerStyleRemote // Just use whatever ArcGIS hands back
} MGSMarkerStyle;

@interface MGSMarker : NSObject
@property (strong) UIImage *icon;
@property (strong) UIColor *color;
@property (strong) UIBezierPath *path;
@property (assign) CGSize size;
@property (assign) MGSMarkerStyle style;
@end
