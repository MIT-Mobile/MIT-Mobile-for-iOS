#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RetailVenue;

@interface RetailDay : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) RetailVenue *venue;

+ (RetailDay *)newDayWithDictionary:(NSDictionary* )dict;
- (NSString *)hoursSummary;

@end
