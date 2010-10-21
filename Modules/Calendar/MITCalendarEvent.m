#import "MITCalendarEvent.h"
#import "EventCategory.h"
#import "CalendarDataManager.h"
#import "CoreDataManager.h"

@implementation MITCalendarEvent 

@dynamic location;
@dynamic latitude;
@dynamic longitude;
@dynamic shortloc;
@dynamic start;
@dynamic end;
@dynamic eventID;
@dynamic title;
@dynamic phone;
@dynamic summary;
@dynamic url;
@dynamic categories;
@dynamic lastUpdated;
@dynamic isRegular;

- (NSString *)subtitle
{
	NSString *dateString = [self dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
	
	if (self.shortloc) {
		return [NSString stringWithFormat:@"%@ | %@", dateString, self.shortloc];
	} else {
		return dateString;
	}	
}

- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:2];
	if (dateStyle != NSDateFormatterNoStyle) {
	
		[formatter setDateStyle:dateStyle];
	
		NSString *dateString = [formatter stringFromDate:self.start];
		if ([self.end timeIntervalSinceDate:self.start] >= 86400.0) {
			dateString = [NSString stringWithFormat:@"%@-%@", dateString, [formatter stringFromDate:self.end]];
		}

		[parts addObject:dateString];
		[formatter setDateStyle:NSDateFormatterNoStyle];
	}

	if (timeStyle != NSDateFormatterNoStyle) {
		[formatter setTimeStyle:timeStyle];
		NSString *timeString = nil;
	
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *startComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.start];
		NSDateComponents *endComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.end];
	
		NSTimeInterval interval = [self.end timeIntervalSinceDate:self.start];
		if (startComps.hour == 0 && startComps.minute == 0 && endComps.hour == 0 && endComps.minute == 0) {
			timeString = [NSString string];
		} else if (interval == 0) {
			timeString = [formatter stringFromDate:self.start];
		} else if (interval == 86340.0) { // seconds between 12:00am and 11:59pm
			timeString = [NSString stringWithString:@"All day"];
		} else {
			timeString = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:self.start], [formatter stringFromDate:self.end]];
		}
		
		[parts addObject:timeString];
	}
	
	[formatter release];
	
	return [parts componentsJoinedByString:separator];
}

- (BOOL)hasCoords
{
    return ([self.latitude doubleValue] != 0);
}

- (void)updateWithDict:(NSDictionary *)dict
{
	self.eventID = [NSNumber numberWithInt:[[dict objectForKey:@"id"] intValue]];

	self.start = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"start"] doubleValue]];
	self.end = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"end"] doubleValue]];
	self.summary = [dict objectForKey:@"description"];
	self.title = [dict objectForKey:@"title"];

	// optional strings
	NSString *maybeValue = [dict objectForKey:@"shortloc"];
	if (maybeValue.length > 0) {
		self.shortloc = maybeValue;
	}
	maybeValue = [dict objectForKey:@"location"];
	if (maybeValue.length > 0) {
		self.location = maybeValue;
	}

	if ([dict objectForKey:@"infophone"] != [NSNull null]) {
		self.phone = [dict objectForKey:@"infophone"];
	}
	if ([dict objectForKey:@"infourl"] != [NSNull null]) {
		self.url = [dict objectForKey:@"infourl"];
	}

	NSDictionary *coordinate = nil;
	if (coordinate = [dict objectForKey:@"coordinate"]) {
		self.latitude = [NSNumber numberWithDouble:[[coordinate objectForKey:@"lat"] doubleValue]];
		self.longitude = [NSNumber numberWithDouble:[[coordinate objectForKey:@"lon"] doubleValue]];
	}
    
	// populate event-category relationships
	NSArray *catArray = nil;
	if (catArray = [dict objectForKey:@"categories"]) {
		for (NSDictionary *catDict in catArray) {
			NSString *name = [catDict objectForKey:@"name"];
			NSInteger catID = [[catDict objectForKey:@"catid"] intValue];
			
			EventCategory *category = [CalendarDataManager categoryWithID:catID];
            if (category.title == nil) {
                category.title = name;
            }
            [self addCategory:category];
			// TODO: also remove events from categories if they changed
		}
	}
    
    self.lastUpdated = [NSDate date];
	[CoreDataManager saveData];
}

- (void)addCategory:(EventCategory *)category
{
    if (![self.categories containsObject:category]) {
        [self addCategoriesObject:category];
        
        NSInteger catID = [category.catID intValue];
        if (catID == kCalendarAcademicCategoryID || catID == kCalendarHolidayCategoryID) {
            
            self.isRegular = [NSNumber numberWithBool:NO];
        }
        
        [CoreDataManager saveData];
    }
}

- (NSString *)description
{
    return self.title;
}

@end
