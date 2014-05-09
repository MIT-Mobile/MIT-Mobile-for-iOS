#import "DiningData.h"

#import "DiningRoot.h"
#import "HouseVenue.h"
#import "RetailVenue.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "ModuleVersions.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface DiningData ()

@property (nonatomic, strong, readonly) DiningRoot *root;
@property (nonatomic, strong) NSOperationQueue *loadingQueue;

@end

@implementation DiningData

+ (DiningData *)sharedData {
    static DiningData *_sharedData = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedData = [[self alloc] init];
        _sharedData.loadingQueue = [[NSOperationQueue alloc] init];
        _sharedData.loadingQueue.maxConcurrentOperationCount = 1;
    });
    
    return _sharedData;
}

- (DiningRoot *)root {
    // There should only be one DiningRoot
    NSArray *roots = [CoreDataManager objectsForEntity:@"DiningRoot" matchingPredicate:nil];
    DiningRoot *root = [roots lastObject];
    return root;
}

- (NSString *)announcementsHTML {
    return self.root.announcementsHTML;
}

- (NSArray *)links {
    NSArray *links = [CoreDataManager objectsForEntity:@"DiningLink" matchingPredicate:nil sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:YES]]];
    return links;
}

- (NSDate *)lastUpdated {
    return self.root.lastUpdated;
}

- (void)reloadAndCompleteWithBlock:(void (^)(NSError *error))completionBlock {
    NSURLRequest *request = [NSURLRequest requestForModule:@"dining" command:nil parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        if (error) {
            DDLogInfo(@"Dining data failed to load. Error: %@", [error debugDescription]);
            if (completionBlock) {
                completionBlock(error);
            }
        } else {
            if (![jsonResult isKindOfClass:[NSDictionary class]]) {
                NSString *message =[NSString stringWithFormat:@"%@ received JSON result as %@, not NSDictionary.", NSStringFromClass([self class]), NSStringFromClass([jsonResult class])];
                DDLogError(@"%@",message);
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                     code:NSURLErrorResourceUnavailable
                                                 userInfo:@{NSLocalizedDescriptionKey : message}];
                if (completionBlock) {
                    completionBlock(error);
                }
            } else {
                [self importData:jsonResult completionBlock:completionBlock];
            }
        }
    };
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

/** Loads the data from the specified dictionary into the CoreData model and then
 executes the passed completion block. The completion block is called regardless
 of whether the import succeeded or failed.
 
 @param dataDict The data to import
 @param completionBlock A block that is called after the import completes
 @see reloadAndCompleteWithBlock:
 */
- (void)importData:(NSDictionary *)dataDict completionBlock:(void (^)(NSError* error))completionBlock
{
    [self.loadingQueue addOperationWithBlock:^(void) {
        // Fetch data
        if (dataDict) {
            // (bskinner)
            // Added to get around issues with CoreDataManager context caching. CoreDataManager keeps
            // a single context per thread and will reuse them in a dirty state.
            // Since NSOperationQueue reuses its thread, we are getting a stale, modified context
            // from CoreDataManager which leads to merge conflicts in certain instances. Forcing a reset
            // in this case should work but it is still likely a VeryBadThing (especially in other cases
            // where multiple operations could be happening on a shared thread).
            [[[CoreDataManager coreDataManager] managedObjectContext] reset];
            
            // Make sure the set list of dietary flags already exist before we start parsing.
            [DiningDietaryFlag createDietaryFlagsInStore];
            
            self.allFlags = [CoreDataManager fetchDataForAttribute:@"DiningDietaryFlag"];
            
            // Find already favorited venues and hold on to reference
            NSArray *favoritedNames = [[CoreDataManager objectsForEntity:@"RetailVenue"
                                                       matchingPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"]] valueForKey:@"shortName"];
            
            // Make list of old entities to delete
            NSArray *oldRoot = [CoreDataManager fetchDataForAttribute:@"DiningRoot"];
            // Delete old things
            [CoreDataManager deleteObjects:oldRoot];
            // Create new entities in Core Data
            DiningRoot *newRoot = [DiningRoot newRootWithDictionary:dataDict];
            
            if (newRoot) {
                newRoot.lastUpdated = [NSDate date];
            }
            
            // set favorites in new data using kept reference
            if ([favoritedNames count]) {
                NSArray *migratedFavorites = [CoreDataManager objectsForEntity:@"RetailVenue" matchingPredicate:[NSPredicate predicateWithFormat:@"shortName IN %@", favoritedNames]];
                [migratedFavorites setValue:@(YES) forKey:@"favorite"];
            }
            
            // Save
            [CoreDataManager saveData];
        }
        
        if (completionBlock) {
            completionBlock(nil);
        }
    }];
}

- (NSDictionary *)fetchSampleData {
    static NSInteger i = 0;
    NSArray *samplePaths = @[@"dining-sample-1", @"dining-sample-2"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:samplePaths[i] ofType:@"json" inDirectory:@"dining"];
    // Uncomment this line to make the app load a different data set each time the main dining view appears.
    i = (i + 1) % 2;
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
        return nil;
    } else {
        return parsedData;
    }
}

@end
