#import <Foundation/Foundation.h>

@interface MITCalendarEventDateParser : NSObject

+ (NSArray *)getSortedDatesForEvents:(NSArray *)events;
+ (NSDictionary *)getDateKeyedDictionaryForEvents:(NSArray *)events;

@end
