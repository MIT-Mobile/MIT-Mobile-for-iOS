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
@dynamic lists;

- (NSString *)subtitle
{
	NSString *dateString = [self dateStringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle separator:@" "];
	
	if (self.shortloc) {
		return [NSString stringWithFormat:@"%@ | %@", dateString, self.shortloc];
	} else {
		return dateString;
	}	
}

- (BOOL)hasMoreDetails {
	MITEventList *aList = [self.lists anyObject];
	if (aList) {
		return [[CalendarDataManager sharedManager] isDailyEvent:aList];
	}
	return YES; // if we have no idea what the source is, then always try to get more details
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
        
        if (self.end) {
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *startComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.start];
            NSDateComponents *endComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.end];
            NSTimeInterval interval = [self.end timeIntervalSinceDate:self.start];
            // only a date with no time -> no time displayed
            if (startComps.hour == 0 && startComps.minute == 0 && endComps.hour == 0 && endComps.minute == 0) {
                timeString = [NSString string];
                // identical start and end times -> just start time displayed
            } else if (interval == 0 ||
                       // starts at the same time every day -> just start time displayed
                       // TODO: account for daylight savings time boundaries
                       fmod(interval, 24 * 60 * 60) == 0) {
                timeString = [formatter stringFromDate:self.start];
                // ?
            } else if (interval == 86340.0) { // seconds between 12:00am and 11:59pm
                timeString = @"All day";
                // fallback to showing time range
            } else {
                timeString = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:self.start], [formatter stringFromDate:self.end]];
            }
        } else {
            timeString = [formatter stringFromDate:self.start];
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
    double endTime = [[dict objectForKey:@"end"] doubleValue];
    if (endTime) {
        self.end = [NSDate dateWithTimeIntervalSince1970:endTime];
    }
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

	NSDictionary *coordinate = [dict objectForKey:@"coordinate"];
	if (coordinate) {
		self.latitude = [NSNumber numberWithDouble:[[coordinate objectForKey:@"lat"] doubleValue]];
		self.longitude = [NSNumber numberWithDouble:[[coordinate objectForKey:@"lon"] doubleValue]];
	}
    
	// populate event-category relationships
	NSArray *catArray = [dict objectForKey:@"categories"];
	if (catArray) {
		for (NSDictionary *catDict in catArray) {
			NSString *name = [catDict objectForKey:@"name"];
			NSInteger catID = [[catDict objectForKey:@"catid"] intValue];
			
			EventCategory *category = [CalendarDataManager categoryWithID:catID forListID:nil];
            if (category.title == nil) {
                category.title = name;
            }
			[self addCategoriesObject:category];
		}
	}

    self.lastUpdated = [NSDate date];
	[CoreDataManager saveData];
}
/*
- (NSString *)description
{
    return self.title;
}
*/

- (void)setUpEKEvent:(EKEvent *)ekEvent {
    ekEvent.title = self.title;
    ekEvent.startDate = self.start;
    ekEvent.endDate = self.end;
    if (self.location.length > 0) {
        ekEvent.location = self.location;
    }
    else if (self.shortloc.length > 0) {
        ekEvent.location = self.shortloc;
    }
}

@end
