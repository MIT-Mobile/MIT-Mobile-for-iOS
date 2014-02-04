#import <Foundation/Foundation.h>

@interface MITResultsPager : NSObject
+ (instancetype)resultsPagerWithResponse:(NSHTTPURLResponse*)response;

- (BOOL)firstPage:(void (^)(NSArray *objects, NSError *error))block;
- (BOOL)lastPage:(void (^)(NSArray *objects, NSError *error))block;
- (BOOL)nextPage:(void (^)(NSArray *objects, NSError *error))block;
- (BOOL)previousPage:(void (^)(NSArray *objects, NSError *error))block;
@end
