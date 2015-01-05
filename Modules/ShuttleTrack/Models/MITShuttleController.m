#import "MITShuttleController.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleVehicleList.h"
#import <RestKit/RKManagedObjectMappingOperationDataSource.h>
#import <RestKit/RKManagedObjectStore.h>
#import "MITShuttlePredictionList.h"

typedef void(^MITShuttleCompletionBlock)(id object, NSError *error);

@interface MITShuttleController ()

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

#pragma mark - Routes/Stops

- (void)getRoutes:(MITShuttleRoutesCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesRoutesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [self handleResult:result error:error completion:completion returnObjectShouldBeArray:YES];
                                                }];
}

- (void)getRouteDetail:(MITShuttleRoute *)route completion:(MITShuttleRouteDetailCompletionBlock)completion
{
    [self getObjectForURL:[NSURL URLWithString:route.url] completion:^(id object, NSError *error) {
        if (!error) {
            NSDate *timestamp = [NSDate date];
            MITShuttleRoute *route = object;
            for (MITShuttleStop *stop in route.stops) {
                stop.predictionList.updatedTime = timestamp;
            }
        }
        completion(object, error);
    }];
}

- (void)getStopDetail:(MITShuttleStop *)stop completion:(MITShuttleStopDetailCompletionBlock)completion
{
    [self getObjectForURL:[NSURL URLWithString:stop.url] completion:^(id object, NSError *error) {
        MITShuttleStop *stop = object;
        stop.predictionList.updatedTime = [NSDate date];
        completion(object, error);
    }];
}

#pragma mark - Predictions

- (void)getPredictionsForRoute:(MITShuttleRoute *)route completion:(MITShuttlePredictionsCompletionBlock)completion
{
    [self getObjectsForURL:[NSURL URLWithString:route.predictionsURL] completion:^(id object, NSError *error) {
        if (!error) {
            NSDate *timestamp = [NSDate date];
            for (MITShuttlePredictionList *list in object) {
                list.updatedTime = timestamp;
            }
        }
        completion(object, error);
    }];
}

- (void)getPredictionsForStop:(MITShuttleStop *)stop completion:(MITShuttlePredictionsCompletionBlock)completion
{
    if (stop.predictionsURL) {
        [self getObjectsForURL:[NSURL URLWithString:stop.predictionsURL] completion:^(id object, NSError *error) {
            NSDate *timestamp = [NSDate date];
            for (MITShuttlePredictionList *list in object) {
                list.updatedTime = timestamp;
            }
            completion(object, error);
        }];
    } else {
        completion(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]);
    }
}

- (void)getPredictionsForStops:(NSArray *)stops completion:(MITShuttlePredictionsCompletionBlock)completion
{
    MITShuttlePredictionsRequestData *requestData = [[MITShuttlePredictionsRequestData alloc] init];
    
    for (MITShuttleStop *stop in stops) {
        [requestData addStop:stop];
    }
    
    [self getPredictionsForPredictionsRequestData:requestData completion:completion];
}

- (void)getPredictionsForPredictionsRequestData:(MITShuttlePredictionsRequestData *)requestData completion:(MITShuttlePredictionsCompletionBlock)completion
{
    // API can only return predictions for one agency at a time
    dispatch_group_t agencyRequestGroup = dispatch_group_create();
    
    for (NSString *agency in requestData.agencies) {
        NSArray *tuples = [requestData tuplesForAgency:agency];
        if (tuples.count > 0) {
            dispatch_group_enter(agencyRequestGroup);
        }
    }
    
    BOOL atLeastOneTupleAdded = NO;
    __block NSMutableArray *aggregatePredictions = [NSMutableArray array];
    __block NSError *aggregateError = nil;
    __block NSMutableString *aggregateErrorDescription = [NSMutableString string];
    
    for (NSString *agency in requestData.agencies) {
        NSArray *tuples = [requestData tuplesForAgency:agency];
        if (tuples.count < 1) {
            continue;
        }
        
        atLeastOneTupleAdded = YES;
        
        NSMutableString *stopAndRouteIdTuples = [NSMutableString stringWithString:tuples[0]];
        for (NSInteger i = 1; i < tuples.count; i++) {
            [stopAndRouteIdTuples appendString:@";"];
            [stopAndRouteIdTuples appendString:tuples[i]];
        }
        
        [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesPredictionsResourceName
                                                    parameters:@{@"agency": agency,
                                                                 @"stops": [NSString stringWithString:stopAndRouteIdTuples]}
                                                    completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                        if (!error) {
                                                            NSDate *timestamp = [NSDate date];
                                                            for (MITShuttlePredictionList *list in result.array) {
                                                                list.updatedTime = timestamp;
                                                            }
                                                        }
                                                        [self handleResult:result error:error completion:^(id object, NSError *error) {
                                                            if (error) {
                                                                if (aggregateErrorDescription.length > 0) {
                                                                    [aggregateErrorDescription appendString:@", "];
                                                                }
                                                                [aggregateErrorDescription appendFormat:@"Request for agency: %@ failed with info: %@", agency, error.localizedDescription];
                                                            }
                                                            [aggregatePredictions addObjectsFromArray:object];
                                                            dispatch_group_leave(agencyRequestGroup);
                                                        } returnObjectShouldBeArray:YES];
                                                    }];
    }
    
    dispatch_group_notify(agencyRequestGroup, dispatch_get_main_queue(), ^{
        if (!atLeastOneTupleAdded) {
            completion(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnsupportedURL userInfo:@{NSLocalizedDescriptionKey: @"The predictions request must include at least one stop"}]);
        } else {
            if (aggregateErrorDescription.length > 0) {
                aggregateError = [NSError errorWithDomain:@"MITShuttleMultiplePredictionRequestsErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: aggregateErrorDescription}];
            }
            completion(aggregatePredictions, aggregateError);
        }
    });
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

- (NSArray *)loadDefaultShuttleRoutes
{
    if (![self hasLoadedDefaultRoutes]) {
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
    } else {
        return nil;
    }
}

- (BOOL)hasLoadedDefaultRoutes
{
    return [self numberOfStoredShuttleRoutes] > 0;
}

- (NSInteger)numberOfStoredShuttleRoutes
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShuttleRoute" inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
    
    if (!error) {
        return count;
    }
    else {
        return -1;
    }
    
}

@end

@interface MITShuttlePredictionsRequestData ()

@property (nonatomic, strong) NSMutableDictionary *tuplesByAgency;
@end

@implementation MITShuttlePredictionsRequestData

- (id)init
{
    self = [super init];
    
    if (self) {
        self.tuplesByAgency = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)addStop:(MITShuttleStop *)stop
{
    NSString *agency = stop.route.agency;
    NSString *tuple = stop.stopAndRouteIdTuple;
    
    [self addTuple:tuple forAgency:agency];
}

- (void)addTuple:(NSString *)tuple forAgency:(NSString *)agency
{
    if (![[self.tuplesByAgency allKeys] containsObject:agency]) {
        [self.tuplesByAgency setObject:[NSMutableArray arrayWithObject:tuple] forKey:agency];
    } else {
        NSMutableArray *tuples = [self.tuplesByAgency objectForKey:agency];
        if (![tuples containsObject:tuple]) {
            [tuples addObject:tuple];
        }
    }
}

- (NSArray *)tuplesForAgency:(NSString *)agency
{
    NSMutableArray *mutableTuples = [self.tuplesByAgency objectForKey:agency];
    return [NSArray arrayWithArray:mutableTuples];
}

- (NSArray *)agencies
{
    return [self.tuplesByAgency allKeys];
}

@end
