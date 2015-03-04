#import <Foundation/Foundation.h>


@interface NSDateFormatter (RelativeString)
+ (NSString*)relativeDateStringFromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;
@end
