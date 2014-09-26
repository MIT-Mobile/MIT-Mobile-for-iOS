#import <Foundation/Foundation.h>

@interface MITLibrariesSearchController : NSObject

@property (nonatomic, readonly) NSString *currentSearchTerm;
@property (nonatomic, readonly) NSArray *results;
@property (nonatomic, readonly) BOOL hasMoreResults;

- (void)search:(NSString *)searchTerm completion:(void (^)(NSError *error))completion;
- (void)getNextResults:(void (^)(NSError *error))completion;

@end
