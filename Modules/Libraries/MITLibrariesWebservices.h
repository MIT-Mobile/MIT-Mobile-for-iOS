#import <Foundation/Foundation.h>

@class MITLibrariesItem;

@interface MITLibrariesWebservices : NSObject

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion;
+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion;
+ (void)getResultsForSearch:(NSString *)searchString
              startingIndex:(NSInteger)startingIndex
                completion:(void (^)(NSArray *items, NSInteger nextIndex, NSInteger totalResults,  NSError *error))completion;
+ (void)getItemDetailsForItem:(MITLibrariesItem *)item
                   completion:(void (^)(MITLibrariesItem *item, NSError *error))completion;


@end
