#import <Foundation/Foundation.h>
#import "MITInitializableWithDictionaryProtocol.h"
#import <RestKit/ISO8601DateFormatterValueTransformer.h>

@class MITLibrariesWorldcatItem, MITLibrariesUser;

@interface MITLibrariesWebservices : NSObject

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion;
+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion;
+ (void)getResultsForSearch:(NSString *)searchString
              startingIndex:(NSInteger)startingIndex
                completion:(void (^)(NSArray *items, NSInteger nextIndex, NSInteger totalResults,  NSError *error))completion;
+ (void)getItemDetailsForItem:(MITLibrariesWorldcatItem *)item
                   completion:(void (^)(MITLibrariesWorldcatItem *item, NSError *error))completion;
+ (void)getUserWithCompletion:(void (^)(MITLibrariesUser *user, NSError *error))completion;

+ (NSArray *)parseJSONArray:(NSArray *)JSONArray intoObjectsOfClass:(Class)initializableDictionaryClass;
+ (RKISO8601DateFormatter *)librariesDateFormatter;

@end
