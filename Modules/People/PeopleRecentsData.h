#import <Foundation/Foundation.h>
#import "PersonDetails.h"


@interface PeopleRecentsData : NSObject {
	
	NSMutableArray *recents;
}

@property (nonatomic, retain) NSMutableArray *recents;

+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails withSearchResult:(NSDictionary *)searchResult;
+ (PersonDetails *)createFromSearchResult:(NSDictionary *)searchResult;

@end
