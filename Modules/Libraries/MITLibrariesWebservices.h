#import <Foundation/Foundation.h>

@class MITLibrariesWorldcatItem;

@interface MITLibrariesWebservices : NSObject

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion;
+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion;
+ (void)getResultsForSearch:(NSString *)searchString
              startingIndex:(NSInteger)startingIndex
                completion:(void (^)(NSArray *items, NSInteger nextIndex, NSInteger totalResults,  NSError *error))completion;
+ (void)getItemDetailsForItem:(MITLibrariesWorldcatItem *)item
                   completion:(void (^)(MITLibrariesWorldcatItem *item, NSError *error))completion;


@end
