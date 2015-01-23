#import "MITCalendarsEvent.h"
#import "MITCalendarsSeriesInfo.h"
#import "MITCalendarsSponsor.h"
#import "MITCalendarsCalendar.h"

#import <EventKit/EventKit.h>

@implementation MITCalendarsEvent

@dynamic identifier;
@dynamic url;
@dynamic startAt;
@dynamic endAt;
@dynamic title;
@dynamic htmlDescription;
@dynamic tickets;
@dynamic cost;
@dynamic openTo;
@dynamic ownerID;
@dynamic lecturer;
@dynamic cancelled;
@dynamic typeCode;
@dynamic statusCode;
@dynamic createdBy;
@dynamic createdAt;
@dynamic modifiedBy;
@dynamic modifiedAt;
@dynamic location;
@dynamic categories;
@dynamic sponsors;
@dynamic contact;
@dynamic seriesInfo;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"start_at" : @"startAt",
                                                  @"end_at"  : @"endAt",
                                                  @"description_html" : @"htmlDescription",
                                                  @"open_to" : @"openTo",
                                                  @"owner_id" : @"ownerID",
                                                  @"type_code" : @"typeCode",
                                                  @"status_code" : @"statusCode",
                                                  @"created_by" : @"createdBy",
                                                  @"created_at" : @"createdAt",
                                                  @"modified_by" : @"modifiedBy",
                                                  @"modified_at" : @"modifiedAt"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"title", @"tickets", @"cost", @"lecturer", @"cancelled"]];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:[MITCalendarsLocation objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"contact" toKeyPath:@"contact" withMapping:[MITCalendarsContact objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"series_info" toKeyPath:@"seriesInfo" withMapping:[MITCalendarsSeriesInfo objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"sponsors" toKeyPath:@"sponsors" withMapping:[MITCalendarsSponsor objectMapping]]];
    
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSMutableArray *parts = [[NSMutableArray alloc] init];
    
	if (dateStyle != NSDateFormatterNoStyle) {
		[formatter setDateStyle:dateStyle];
        
		NSString *dateString = [formatter stringFromDate:self.startAt];
		if ([self.endAt timeIntervalSinceDate:self.startAt] >= 86400.0) {
			dateString = [NSString stringWithFormat:@"%@-%@", dateString, [formatter stringFromDate:self.endAt]];
		}
        
		[parts addObject:dateString];
		[formatter setDateStyle:NSDateFormatterNoStyle];
	}
    
	if (timeStyle != NSDateFormatterNoStyle) {
		[formatter setTimeStyle:timeStyle];
		NSString *timeString = nil;
        
        if (self.endAt) {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *startComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.startAt];
            NSDateComponents *endComps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.endAt];
            NSTimeInterval interval = [self.endAt timeIntervalSinceDate:self.startAt];
            // only a date with no time -> no time displayed
            if (startComps.hour == 0 && startComps.minute == 0 && endComps.hour == 0 && endComps.minute == 0) {
                timeString = @"";
                // identical start and end times -> just start time displayed
            } else if (interval == 0 ||
                       // starts at the same time every day -> just start time displayed
                       // TODO: account for daylight savings time boundaries
                       fmod(interval, 24 * 60 * 60) == 0) {
                timeString = [formatter stringFromDate:self.startAt];
                // ?
            } else if (interval == 86340.0) { // seconds between 12:00am and 11:59pm
                timeString = @"All day";
                // fallback to showing time range
            } else {
                timeString = [NSString stringWithFormat:@"%@-%@", [formatter stringFromDate:self.startAt], [formatter stringFromDate:self.endAt]];
            }
        } else {
            timeString = [formatter stringFromDate:self.startAt];
        }
		
		[parts addObject:timeString];
	}
	
	return [parts componentsJoinedByString:separator];
}

- (void)setUpEKEvent:(EKEvent *)ekEvent {
    ekEvent.title = self.title;
    ekEvent.startDate = self.startAt;
    ekEvent.endDate = self.endAt;
    if (self.contact.websiteURL) {
        ekEvent.URL = [NSURL URLWithString:self.contact.websiteURL];
    }
    ekEvent.location = [self.location locationString];
    ekEvent.notes = self.htmlDescription;
}

- (BOOL)isHoliday
{
    return [self.statusCode isEqualToString:@"H"];
}

@end