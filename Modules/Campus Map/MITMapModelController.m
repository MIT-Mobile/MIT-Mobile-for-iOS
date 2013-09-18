#import "MITMapModelController.h"
#import "MobileRequestOperation.h"

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

@end
