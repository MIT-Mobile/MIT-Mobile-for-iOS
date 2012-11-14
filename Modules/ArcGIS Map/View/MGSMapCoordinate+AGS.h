#import "MGSMapCoordinate.h"

@class AGSPoint;
@class AGSGeometryEngine;

@interface MGSMapCoordinate (AGS)
@property (nonatomic, strong) AGSPoint *agsPoint;
+ (AGSGeometryEngine*)sharedGeometryEngine;
@end
