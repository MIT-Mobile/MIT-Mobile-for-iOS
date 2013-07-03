#import "DiningData.h"

#import "DiningRoot.h"
#import "HouseVenue.h"
#import "RetailVenue.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "ModuleVersions.h"
#import "MobileRequestOperation.h"
#import "JSON.h"

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

- (void)reloadAndCompleteWithBlock:(void (^)())completionBlock {
    [self.loadingQueue addOperationWithBlock:^(void) {
        // Fetch data
        NSDictionary *latestDataDict = [self fetchData];
        
        if (latestDataDict) {
            [[CoreDataManager managedObjectContext] processPendingChanges];
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
            DiningRoot *newRoot = [DiningRoot newRootWithDictionary:latestDataDict];
            
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
        completionBlock();
    }];
}

- (NSDictionary *)fetchData {
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
