#import "MITMapModelController.h"
#import "MobileRequestOperation.h"
#import "MITMapCategory.h"

static NSString* const MITMapResourceCategoryTitles = @"categorytitles";
static NSString* const MITMapResourceCategory = @"category";

@interface MITMapModelController ()
@property (nonatomic,strong) NSOperationQueue *requestQueue;
@end

@implementation MITMapModelController
+ (MITMapModelController*)sharedController
{
    static MITMapModelController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[MITMapModelController alloc] init];
    });
    
    return sharedController;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMapResponse)block
{
    if (block) {
        NSDictionary *parameters = nil;
        if (queryString) {
            parameters = @{@"q" : queryString};
        }
        
        MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                    command:@"search"
                                                                                 parameters:parameters];
        
        apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
            block([NSOrderedSet orderedSetWithArray:content],[NSDate date],YES,error);
        };
        
        [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
    }
}


- (void)placeCategories:(MITMapResponse)block
{
    if (block) {
        MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                    command:@"categorytitles"
                                                                                 parameters:nil];
        
        apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
            NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];
            
            for (NSDictionary *categoryData in content) {
                MITMapCategory *category = [[MITMapCategory alloc] initWithDictionary:categoryData];
                [categories addObject:category];
            }
            
            block(categories, [NSDate date], YES, error);
        };
        
        [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
    }
}

- (void)places:(MITMapResponse)block
{
    
}

- (void)placesInCategory:(NSString*)categoryId loaded:(MITMapResponse)block
{

}

@end
