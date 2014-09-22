#import <Foundation/Foundation.h>

@interface MITLibrariesWebservices : NSObject

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion;
+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion;
+ (void)getResultsForSearch:(NSString *)searchString
              startingIndex:(NSInteger)startingIndex
                completion:(void (^)(NSArray *items, NSInteger nextIndex, NSInteger totalResults,  NSError *error))completion;

@end
