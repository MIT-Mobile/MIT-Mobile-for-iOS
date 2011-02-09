/*
 * this class defines the structure of people details
 * as retrieved from mobi and stored in core data
 *
 */

#import <CoreData/CoreData.h>


@interface PersonDetails : NSManagedObject  
{	
	NSString *uid;
	//NSString *address;
	//NSString *city;
	NSString *dept;
	NSString *email;
	NSString *fax;
	NSString *givenname;
	//NSString *homephone;
	NSString *office;
	//NSString *room;
	//NSString *state;
	NSString *surname;
	NSString *phone;
	NSString *title;
	NSDate *lastUpdate;
}

@property (nonatomic, retain) NSString *uid;
//@property (nonatomic, retain) NSString *address;
//@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *dept;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *givenname;
//@property (nonatomic, retain) NSString *homephone;
@property (nonatomic, retain) NSString *office;
//@property (nonatomic, retain) NSString *room;
//@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *surname;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *lastUpdate;

+ (PersonDetails *)retrieveOrCreate:(NSDictionary *)selectedResult;
- (NSString*)displayName;

@end



