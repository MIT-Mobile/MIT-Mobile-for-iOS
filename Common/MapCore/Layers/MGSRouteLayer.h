#import "MGSLayer.h"

@protocol MGSAnnotation;

@interface MGSRouteLayer : MGSLayer
@property (nonatomic,weak) id<MGSAnnotation> currentStop;
@property (nonatomic,readonly,weak) id<MGSAnnotation> nextStop;
@property (nonatomic,readonly,weak) id<MGSAnnotation> previousStop;

@property (nonatomic,readonly,strong) NSArray *pathCoordinates;
@property (nonatomic,readonly,strong) NSOrderedSet *stops;

@property (nonatomic,assign) BOOL requireIdentification;
@property (nonatomic,assign) BOOL requireHandicapAccess;

- (id)initWithName:(NSString*)name withStops:(NSOrderedSet*)stopAnnotations pathCoordinates:(NSArray*)coordinates;
- (id)initWithName:(NSString*)name withStops:(NSOrderedSet*)stopAnnotations;
@end
