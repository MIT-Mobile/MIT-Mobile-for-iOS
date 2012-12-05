#import "MGSLayer.h"

@class MGSMapAnnotation;
@class MGSMapCoordinate;

@interface MGSRouteLayer : MGSLayer
@property (strong) MGSMapAnnotation *current;
@property (strong,readonly) MGSMapAnnotation *start;
@property (strong,readonly) MGSMapAnnotation *end;

@property (assign) BOOL requireIdentification;
@property (assign) BOOL requireHandicapAccess;

- (void)solveRouteOnCompletion:(void (^)(BOOL routeSuccess, NSError *error))completionBlock;

@end
