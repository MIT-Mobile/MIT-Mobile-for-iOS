#import <Foundation/Foundation.h>
#import "PersonDetails.h"

@interface PeopleFavoriteData : NSObject

+ (void) setPerson:(PersonDetails *)person asFavorite:(BOOL)isFavorite;
+ (NSArray *) retrieveFavoritePeople;
+ (void) movePerson:(PersonDetails *)personDetails fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void) removeAll;

@end
