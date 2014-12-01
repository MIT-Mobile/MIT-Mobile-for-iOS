#import "MITShuttleController.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import <RestKit/RKManagedObjectMappingOperationDataSource.h>
#import <RestKit/RKManagedObjectStore.h>

typedef void(^MITShuttleCompletionBlock)(id object, NSError *error);

@interface MITShuttleController ()
@property (strong, nonatomic) NSMutableDictionary *lastUpdatedPredictionDataRecord;
@property (strong, nonatomic) NSMutableArray *retrievedShuttleRoutes;
@end

@implementation MITShuttleController

#pragma mark - Singleton Instance

+ (MITShuttleController *)sharedController
{
    static MITShuttleController *_sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedController = [[MITShuttleController alloc] init];
    });
    return _sharedController;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Routes/Stops

- (void)getRoutes:(MITShuttleRoutesCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesRoutesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (!error) {
                                                        self.retrievedShuttleRoutes = [result.array mutableCopy];
                                                        for (MITShuttleRoute *shuttleRoute in self.retrievedShuttleRoutes) {
                                                            shuttleRoute.lastUpdatedTimestamp = self.lastUpdatedPredictionDataRecord[shuttleRoute.identifier];
                                                        }
                                                    }
                                                    [self handleResult:result error:error completion:completion returnObjectShouldBeArray:YES];
                                                }];
}

- (void)getRouteDetail:(MITShuttleRoute *)route completion:(MITShuttleRouteDetailCompletionBlock)completion
{
    [self getObjectForURL:[NSURL URLWithString:route.url] completion:completion];
}

- (void)getStopDetail:(MITShuttleStop *)stop completion:(MITShuttleStopDetailCompletionBlock)completion
{
    [self getObjectForURL:[NSURL URLWithString:stop.url] completion:completion];
}

#pragma mark - Predictions

- (void)getPredictionsForRoute:(MITShuttleRoute *)route completion:(MITShuttlePredictionsCompletionBlock)completion
{
    [self getObjectsForURL:[NSURL URLWithString:route.predictionsURL] completion:^(id object, NSError *error) {
        if (!error) {
            if (route.identifier) {
                route.lastUpdatedTimestamp = [NSDate date];
                self.lastUpdatedPredictionDataRecord[route.identifier] = route.lastUpdatedTimestamp;
            }
        }
        completion(object, error);
    }];
}

- (void)getPredictionsForStop:(MITShuttleStop *)stop completion:(MITShuttlePredictionsCompletionBlock)completion
{
    if (stop.predictionsURL) {
        [self getObjectsForURL:[NSURL URLWithString:stop.predictionsURL] completion:completion];
    } else {
        completion(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]);
    }
}

#pragma mark - Vehicles

- (void)getVehicles:(MITShuttleVehiclesCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesVehiclesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [self handleResult:result error:error completion:completion returnObjectShouldBeArray:YES];
                                                }];
}

- (void)getVehiclesForRoute:(MITShuttleRoute *)route completion:(MITShuttleVehiclesCompletionBlock)completion
{
    [self getObjectsForURL:[NSURL URLWithString:route.vehiclesURL] completion:completion];
}

#pragma mark - Helper Methods

- (void)getObjectForURL:(NSURL *)url completion:(MITShuttleCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForURL:url completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        [self handleResult:result error:error completion:completion returnObjectShouldBeArray:NO];
    }];
}

- (void)getObjectsForURL:(NSURL *)url completion:(MITShuttleCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForURL:url completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        [self handleResult:result error:error completion:completion returnObjectShouldBeArray:YES];
    }];
}

- (void)handleResult:(RKMappingResult *)result error:(NSError *)error completion:(MITShuttleCompletionBlock)completion returnObjectShouldBeArray:(BOOL)alwaysReturnArray
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!error) {
            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
            NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
            if (completion) {
                if ([objects count] > 1 || alwaysReturnArray) {
                    completion(objects, nil);
                } else {
                    completion([objects firstObject], nil);
                }
            }
        } else {
            if (completion) {
                completion(nil, error);
            }
        }
    }];
}

#pragma mark - Default Routes Data

+ (NSArray *)loadDefaultShuttleRoutes
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MITShuttlesDefaultRoutesData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSArray *defaultRoutes;
    if (data) {
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSString* MIMEType = @"application/json";
        NSError* error;
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id parsedData = [RKMIMETypeSerialization objectFromData:data MIMEType:MIMEType error:&error];
        if (parsedData == nil && error) {
            NSLog(@"Error parsing default shuttle routes! %@", error);
        } else {
            NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
            NSDictionary *mappings = @{[NSNull new] : [MITShuttleRoute objectMapping]};
            RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:parsedData mappingsDictionary:mappings];
            RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:context cache:[MITMobile defaultManager].managedObjectStore.managedObjectCache];
            mapper.mappingOperationDataSource = dataSource;
            [mapper execute:nil];
            defaultRoutes = mapper.mappingResult.array;
        }
    }
    
    return defaultRoutes;
}

#pragma mark - Getters | Setters

- (NSMutableDictionary *)lastUpdatedPredictionDataRecord
{
    if (!_lastUpdatedPredictionDataRecord) {
        _lastUpdatedPredictionDataRecord = [NSMutableDictionary dictionary];
    }
    return _lastUpdatedPredictionDataRecord;
}

- (NSMutableArray *)retrievedShuttleRoutes
{
    if (!_retrievedShuttleRoutes) {
        _retrievedShuttleRoutes = [NSMutableArray array];
    }
    return _retrievedShuttleRoutes;
}

@end
