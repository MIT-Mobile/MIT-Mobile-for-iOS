#import "MITShuttlesResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"

@implementation MITShuttleRoutesResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesRoutesResourceName pathPattern:MITShuttlesRoutesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleRoute objectMappingFromAllRoutes]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

- (NSArray *)fetchRequestForURLBlocks
{
    NSFetchRequest *(^fetchRequestForRouteBlock)(NSURL *URL) = ^NSFetchRequest *(NSURL *URL) {
        RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[URL relativePath] stringByAppendingString:@"/"]];
        
        NSDictionary *parameters = nil;
        BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
        
        if (matches) {
            NSFetchRequest *fetchRequestForRoute = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleRoute entityName]];
            fetchRequestForRoute.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
            return fetchRequestForRoute;
        }
        
        return nil;
    };
    
    NSFetchRequest *(^fetchRequestForChildStopsBlock)(NSURL *URL) = ^NSFetchRequest *(NSURL *URL) {
        RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[URL relativePath] stringByAppendingString:@"/"]];
        
        NSDictionary *parameters = nil;
        BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
        
        if (matches) {
            NSFetchRequest *fetchRequestForChildStops = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleStop entityName]];
            fetchRequestForChildStops.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
            return fetchRequestForChildStops;
        }
        
        return nil;
    };
    
    return @[fetchRequestForRouteBlock, fetchRequestForChildStopsBlock];
}

@end

@implementation MITShuttleRouteDetailResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesRouteResourceName pathPattern:MITShuttlesRoutePathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleRoute objectMappingFromDetail]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttleStopDetailResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesStopResourceName pathPattern:MITShuttlesStopPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleStop objectMappingFromDetail]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttlePredictionsResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesPredictionsResourceName pathPattern:MITShuttlesPredictionsPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttlePredictionList objectMappingFromDetail]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttleVehiclesResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesVehiclesResourceName pathPattern:MITShuttlesVehiclesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleVehicleList objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequestForURL:(NSURL *)url
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[[url relativePath] stringByAppendingString:@"/"]];
    
    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];

    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleVehicle entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        return fetchRequest;
    }
    return nil;
}

@end
