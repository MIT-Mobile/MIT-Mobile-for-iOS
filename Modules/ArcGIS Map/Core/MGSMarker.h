#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    MGSMarkerStylePin = 0,
    MGSMarkerStyleFill,
    MGSMarkerStyleStroke,
    MGSMarkerStyleImage,
    MGSMarkerStyleRemote // Just use whatever ArcGIS hands back
} MGSMarkerStyle;

@interface MGSMarker : NSObject
@property (assign) MGSMarkerStyle style;
@property (assign) CGSize size;

@property (strong) UIImage *image;
@property (copy) UIColor *color;
@property (copy) UIBezierPath *path;
@end
