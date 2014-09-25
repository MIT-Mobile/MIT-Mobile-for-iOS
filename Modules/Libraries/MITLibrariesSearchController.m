#import "MITLibrariesSearchController.h"
#import "MITLibrariesWebservices.h"

@interface MITLibrariesSearchController ()

@property (nonatomic, strong) NSString *currentSearchTerm;
@property (nonatomic, strong) NSArray *results;
@property (nonatomic, assign) BOOL hasMoreResults;

@property (nonatomic, assign) NSInteger offsetForNextSearch;

@end

@implementation MITLibrariesSearchController

- (void)search:(NSString *)searchTerm completion:(void (^)(NSError *error))completion
{
    self.currentSearchTerm = searchTerm;
    [MITLibrariesWebservices getResultsForSearch:searchTerm startingIndex:0 completion:^(NSArray *items, NSInteger nextIndex, NSInteger totalResults, NSError *error) {
        if (error) {
            completion(error);
        } else {
            self.results = [NSArray arrayWithArray:items];
            self.hasMoreResults = nextIndex > 0;
            self.offsetForNextSearch = nextIndex;
            completion(nil);
        }
    }];
}

- (void)getNextResults:(void (^)(NSError *error))completion
{
    if (!self.hasMoreResults) {
        return;
    }
    
    [MITLibrariesWebservices getResultsForSearch:self.currentSearchTerm startingIndex:self.offsetForNextSearch completion:^(NSArray *items, NSInteger nextIndex, NSInteger totalResults, NSError *error) {
        NSLog(@"error: %@, total: %i, next: %i", error, totalResults, nextIndex);
        if (error) {
            completion(error);
        } else {
            NSMutableArray *newTotalResults = [NSMutableArray arrayWithArray:self.results];
            [newTotalResults addObjectsFromArray:items];
            self.results = [NSArray arrayWithArray:newTotalResults];
            self.hasMoreResults = nextIndex > 0;
            self.offsetForNextSearch = nextIndex;
            completion(nil);
        }
    }];
}

@end
