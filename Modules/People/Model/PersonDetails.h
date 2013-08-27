/*
 * this class defines the structure of people details
 * as retrieved from mobi and stored in core data
 *
 */

#import <CoreData/CoreData.h>


@interface PersonDetails : NSManagedObject
@property (nonatomic,copy) NSString *uid;
@property (nonatomic,copy) NSString *dept;
@property (nonatomic,copy) NSString *email;
@property (nonatomic,copy) NSString *fax;
@property (nonatomic,copy) NSString *givenname;
@property (nonatomic,copy) NSString *office;
@property (nonatomic,copy) NSString *surname;
@property (nonatomic,copy) NSString *phone;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSDate *lastUpdate;

+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult;
- (NSString*)displayName;

@end



