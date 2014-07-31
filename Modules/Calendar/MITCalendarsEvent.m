#import "MITCalendarsEvent.h"
#import "MITCalendarsContact.h"
#import "MITCalendarsLocation.h"
#import "MITCalendarsSeriesInfo.h"
#import "MITCalendarsSponsor.h"
#import "MITCalendarsCalendar.h"


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
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

@end
