#import "MGSRouteOperation.h"
#import <ArcGIS/ArcGIS.h>

@interface MGSRouteOperation ()
@property (nonatomic,assign,getter=isExecuting) BOOL executing;
@property (nonatomic,assign,getter=isFinished) BOOL finished;

@property (strong) AGSQueryTask *queryTask;
@property (strong) NSOperation *activeOperation;

@property (copy) NSArray *annotations;
@property (strong) NSMutableArray *locatedAnnotations;
@end

@implementation MGSRouteOperation
- (id)initWithStops:(NSArray*)stops completion:(void (^)(NSArray *annotation, NSArray *locatedAnnotations, NSError *error))completionBlock
{
    self = [super init];
    
    if (self)
    {
        self.annotations = stops;
    }
    
    return self;
}

- (void)start
{
    
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)setExecuting:(BOOL)executing
{
    if (self.isExecuting != executing)
    {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished
{
    if (self.isFinished != finished)
    {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}
@end
