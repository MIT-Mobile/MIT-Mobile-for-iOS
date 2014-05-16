#import <Foundation/Foundation.h>
#import "PersonDetails.h"


@interface PeopleRecentsData : NSObject
@property (copy) NSArray *recents;

+ (PersonDetails *)personWithUID:(NSString *)uid;
+ (PeopleRecentsData *)sharedData;
+ (void)eraseAll;
+ (void)erasePerson:(NSString *)uid;
+ (PersonDetails *)updatePerson:(PersonDetails *)personDetails;

@end
