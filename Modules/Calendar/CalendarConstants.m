#import "CalendarConstants.h"

NSString * const CalendarStateEventList = @"events";
NSString * const CalendarStateCategoryList = @"categories";
NSString * const CalendarStateCategoryEventList = @"category";
//NSString * const CalendarStateSearchHome = @"search";
//NSString * const CalendarStateSearchResults = @"results";
NSString * const CalendarStateEventDetail = @"detail";

@implementation CalendarConstants

#pragma mark Event list types (scroller buttons)

NSString * const CalendarEventTitleEvents = @"Events";
NSString * const CalendarEventTitleExhibits = @"Exhibits";
NSString * const CalendarEventTitleAcademic = @"Academic Calendar";
NSString * const CalendarEventTitleHoliday = @"Holidays";
NSString * const CalendarEventTitleCategory = @"Categories";

+ (NSString *)titleForEventType:(CalendarEventListType)listType
{
	switch (listType) {
		case CalendarEventListTypeEvents:
			return CalendarEventTitleEvents;
		case CalendarEventListTypeExhibits:
			return CalendarEventTitleExhibits;
		case CalendarEventListTypeAcademic:
			return CalendarEventTitleAcademic;
		case CalendarEventListTypeHoliday:
			return CalendarEventTitleHoliday;
		case CalendarEventListTypeCategory:
			return CalendarEventTitleCategory;
		default:
			return nil;
	}
}

#pragma mark Parameters for querying server

NSString * const CalendarEventAPIDay = @"day";
NSString * const CalendarEventAPIAcademic = @"academic";
NSString * const CalendarEventAPIHoliday = @"holidays";
NSString * const CalendarEventAPICategory = @"categories";
NSString * const CalendarEventAPISearch = @"search";

+ (NSString *)apiCommandForEventType:(CalendarEventListType)listType
{
	switch (listType) {
		case CalendarEventListTypeEvents:
			return CalendarEventAPIDay;
		case CalendarEventListTypeExhibits:
			return CalendarEventAPIDay;
		case CalendarEventListTypeAcademic:
			return CalendarEventAPIAcademic;
		case CalendarEventListTypeHoliday:
			return CalendarEventAPIHoliday;
		case CalendarEventListTypeCategory:
			return CalendarEventAPICategory;
		default:
			return nil;
	}
}

+ (NSString *)dateStringForEventType:(CalendarEventListType)listType forDate:(NSDate *)aDate
{
	NSDate *now = [NSDate date];	
	if ((listType == CalendarEventListTypeEvents
         || listType == CalendarEventListTypeExhibits)
		&& [now compare:aDate] != NSOrderedAscending
		&& [now timeIntervalSinceDate:aDate] < [CalendarConstants intervalForEventType:listType fromDate:aDate forward:YES]) {
		return @"Today";
	}

	NSString *dateString = nil;
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
    switch (listType) {
        case CalendarEventListTypeAcademic:
            [df setDateFormat:@"MMMM yyyy"];
            dateString = [df stringFromDate:aDate];
            break;
        case CalendarEventListTypeHoliday:
        {
            [df setDateFormat:@"yyyy"];

            // align year with MIT fiscal year.
            // this means our results will be incorrect if MIT ever decides to change
            // the start date of their fiscal year
            // but i doubt that will happen in the next several years
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDateComponents *comps = [[NSDateComponents alloc] init];
            if ([comps month] <= 6) {
                [comps setYear:-1];
                NSDate *earlierDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
                dateString = [NSString stringWithFormat:@"%@-%@", [df stringFromDate:earlierDate], [df stringFromDate:aDate]];
            } else {
                [comps setYear:1];
                NSDate *laterDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
                dateString = [NSString stringWithFormat:@"%@-%@", [df stringFromDate:aDate], [df stringFromDate:laterDate]];
            }
            break;
        }
        default:
            [df setDateStyle:kCFDateFormatterMediumStyle];
            dateString = [df stringFromDate:aDate];
            break;
    }
	
	return dateString;
}

+ (NSTimeInterval)intervalForEventType:(CalendarEventListType)listType fromDate:(NSDate *)aDate forward:(BOOL)forward
{
	NSInteger sign = forward ? 1 : -1;
	switch (listType) {
		case CalendarEventListTypeAcademic:
		{
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDateComponents *comps = [[NSDateComponents alloc] init];
			[comps setMonth:sign];
			NSDate *targetDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
			[comps release];
			return [targetDate timeIntervalSinceDate:aDate];
		}
		case CalendarEventListTypeHoliday:
        {
			NSCalendar *calendar = [NSCalendar currentCalendar];
			NSDateComponents *comps = [[NSDateComponents alloc] init];
			[comps setYear:sign];
			NSDate *targetDate = [calendar dateByAddingComponents:comps toDate:aDate options:0];
			[comps release];
			return [targetDate timeIntervalSinceDate:aDate];
        }
		//case CalendarEventListTypeCategory:
		case CalendarEventListTypeEvents:
		default:
			return 86400.0 * sign;
	}
}

@end
