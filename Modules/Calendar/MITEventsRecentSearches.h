#import <Foundation/Foundation.h>

@interface MITEventsRecentSearches : NSObject

+ (void)saveRecentEventSearch:(NSString *)recentSearch;
+ (NSOrderedSet *)recentSearches;

@end
