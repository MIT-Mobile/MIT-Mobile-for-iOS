#import "DiningModule.h"
#import "DiningMapListViewController.h"
#import "DiningDietaryFlag.h"

#import "MITModule+Protected.h"

@implementation DiningModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag        = DiningTag;
        self.shortName  = @"Dining";
        self.longName   = @"Dining";
        self.iconName   = @"dining";
        [DiningDietaryFlag createDietaryFlagsInStore];
    }
    return self;
}

- (void) loadModuleHomeController
{
    DiningMapListViewController *controller = [[DiningMapListViewController alloc] init];
    self.moduleHomeController = controller;
}

+ (NSDictionary *) loadSampleDataFromFile
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dining-sample" ofType:@"json" inDirectory:@"dining"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSDictionary *sampleData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
    }
    
    return sampleData;
}


@end
