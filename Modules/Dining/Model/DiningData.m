#import "DiningData.h"

#import "HouseVenue.h"
#import "CoreDataManager.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "ModuleVersions.h"
#import "MobileRequestOperation.h"
#import "JSON.h"

@implementation DiningData

+ (DiningData *)sharedData {
    static DiningData *_sharedData = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedData = [[self alloc] init];
    });
    
    return _sharedData;
}

- (id)init {
    self = [super init];
    
    if (self) {

    }

    return self;
}

- (void)loadDebugData {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dining-sample" ofType:@"json" inDirectory:@"dining"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    id sampleData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
    } else {
        [CoreDataManager clearDataForAttribute:@"HouseVenue"];
        [CoreDataManager saveData];
        [self importData:sampleData];
        [CoreDataManager saveData];
    }
}

- (void)importData:(NSDictionary *)parsedJSON {
    if ([parsedJSON respondsToSelector:@selector(objectForKey:)]) {
        NSMutableArray *venues = [NSMutableArray array];
        for (NSDictionary *venueDict in parsedJSON[@"venues"][@"house"]) {
            [venues addObject:[HouseVenue newVenueWithDictionary:venueDict]];
        }
    } else {
        DDLogError(@"Dining JSON is not a dictionary.");
    }
}

@end
