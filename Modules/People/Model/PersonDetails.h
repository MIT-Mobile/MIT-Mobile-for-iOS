/*
 * this class defines the structure of people details
 * as retrieved from mobi and stored in core data
 *
 */

#import <CoreData/CoreData.h>


@interface PersonDetails : NSManagedObject

@property (nonatomic,copy) NSString *uid;
@property (nonatomic,copy) NSString *affiliation;
@property (nonatomic,copy) NSString *city;
@property (nonatomic,copy) NSString *dept;
@property (nonatomic,copy) NSArray  *email;
@property (nonatomic,copy) NSArray  *fax;
@property (nonatomic,copy) NSString *givenname;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSArray  *office;
@property (nonatomic,copy) NSArray  *phone;
@property (nonatomic,copy) NSArray  *home; // homephone
@property (nonatomic,copy) NSString *state;
@property (nonatomic,copy) NSString *street;
@property (nonatomic,copy) NSString *surname;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *url;
@property (nonatomic,copy) NSArray  *website;
@property (nonatomic,copy) NSDate   *lastUpdate;

@property (nonatomic,assign) BOOL favorite;
@property (nonatomic,assign) NSInteger favoriteIndex;

- (NSString *)address;

@end



