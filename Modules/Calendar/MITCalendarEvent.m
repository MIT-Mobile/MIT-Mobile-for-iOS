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
	NSMutableArray *parts = [[NSMutableArray alloc] init];
    
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
                timeString = @"";
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
	
	return [parts componentsJoinedByString:separator];
}

- (BOOL)hasCoords
{
    return ([self.latitude doubleValue] != 0);
}

- (void)updateWithDict:(NSDictionary *)dict
{
	self.eventID = @([dict[@"id"] integerValue]);

	self.start = [NSDate dateWithTimeIntervalSince1970:[dict[@"start"] doubleValue]];
    
    NSTimeInterval endTime = [dict[@"end"] doubleValue];
    if (endTime) {
        self.end = [NSDate dateWithTimeIntervalSince1970:endTime];
    }
    
	self.summary = dict[@"description"];
	self.title = dict[@"title"];

	// optional strings
	NSString *shortLocationName = dict[@"shortloc"];
	if (![shortLocationName isEqual:[NSNull null]] && [shortLocationName length]) {
		self.shortloc = shortLocationName;
	}
    
	NSString *locationName = dict[@"location"];
	if (![locationName isEqual:[NSNull null]] && [locationName length]) {
		self.location = locationName;
	}

    NSString *phone = dict[@"infophone"];
	if (![phone isEqual:[NSNull null]] && [phone length]) {
		self.phone = phone;
	}
    
    NSString *url = dict[@"infourl"];
	if (![url isEqual:[NSNull null]] && [url length]) {
		self.url = url;
	}

	NSDictionary *coordinate = dict[@"coordinate"];
	if (coordinate) {
		self.latitude = @([coordinate[@"lat"] doubleValue]);
		self.longitude = @([coordinate[@"lon"] doubleValue]);
	}
    
	// populate event-category relationships
	NSArray *categories = dict[@"categories"];
	[categories enumerateObjectsUsingBlock:^(NSDictionary *category, NSUInteger idx, BOOL *stop) {
        EventCategory *categoryObject = [CalendarDataManager categoryWithID:[category[@"catid"] integerValue]
                                                                  forListID:nil];
        if (!categoryObject.title) {
            categoryObject.title = category[@"name"];
        }
        
        [self addCategoriesObject:categoryObject];
    }];

    self.lastUpdated = [NSDate date];
	[CoreDataManager saveData];
}

- (void)setUpEKEvent:(EKEvent *)ekEvent {
    ekEvent.title = self.title;
    ekEvent.startDate = self.start;
    ekEvent.endDate = self.end;
    if ([self.location length] > 0) {
        ekEvent.location = self.location;
    } else if ([self.shortloc length] > 0) {
        ekEvent.location = self.shortloc;
    }
}

@end
