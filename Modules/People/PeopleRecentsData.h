#import <Foundation/Foundation.h>
#import "PersonDetails.h"


@interface PeopleRecentsData : NSObject
@property (copy) NSArray *recents;

+ (PersonDetails *)personWithUID:(NSString *)uid;
+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult;
+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult;

@end
