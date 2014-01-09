#import <Foundation/Foundation.h>

@interface MITMobilePaginator : NSObject
@property (nonatomic,readonly) NSUInteger pageSize;

- (instancetype)initWithResourceNamed:(NSString*)resourceName parameters:(NSDictionary*)parameters;

- (BOOL)hasNextPage;
- (void)nextPage:(void (^)(NSArray *objects, NSError *error))block;

- (BOOL)hasPreviousPage;
- (void)previousPage:(void (^)(NSArray *objects, NSError *error))block;

- (BOOL)hasFirstPage;
- (void)firstPage:(void (^)(NSArray *objects, NSError *error))block;

- (BOOL)hasLastPage;
- (void)lastPage:(void (^)(NSArray *objects, NSError *error))block;

@end
