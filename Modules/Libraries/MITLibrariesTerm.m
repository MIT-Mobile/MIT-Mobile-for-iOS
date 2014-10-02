#import "MITLibrariesTerm.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesDate.h"
#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesClosingsTerm.h"
#import "MITLibrariesExceptionsTerm.h"
#import "Foundation+MITAdditions.h"

@implementation MITLibrariesTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"dates" mapping:[MITLibrariesDate objectMapping]];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"regular" toKeyPath:@"regularTerm" withMapping:[MITLibrariesRegularTerm objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"closings" toKeyPath:@"closingsTerm" withMapping:[MITLibrariesClosingsTerm objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"exceptions" toKeyPath:@"exceptionsTerm" withMapping:[MITLibrariesExceptionsTerm objectMapping]]];
    
    return mapping;
}

- (NSString *)termDescription
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
 
    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [self.dateFormatter dateFromString:self.dates.end];
 
    [self.dateFormatter setDateFormat:@"MMM d, yyyy"];
 
    NSString *startDateString = [self.dateFormatter stringFromDate:startDate];
    NSString *endDateString = [self.dateFormatter stringFromDate:endDate];
    
    return [NSString stringWithFormat:@"%@ (%@-%@)", self.name, startDateString, endDateString];
}

- (NSString *)termHoursDescription
{
    NSString *hoursDescription = @"";
    for (MITLibrariesRegularTerm *term in self.regularTerm) {
        hoursDescription = [NSString stringWithFormat:@"%@%@\n", hoursDescription, [term termHoursDescription]];
    }
    
    for (MITLibrariesClosingsTerm *term in self.closingsTerm) {
        hoursDescription = [NSString stringWithFormat:@"%@%@\n", hoursDescription, [term termHoursDescription]];
    }
    
    return [hoursDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)hoursStringForDate:(NSDate *)date
{
    if (![self dateFallsInTerm:date]) {
        return kMITLibraryClosedMessageString;
    }
    
    for (MITLibrariesClosingsTerm *term in self.closingsTerm) {
        if ([term isClosedOnDate:date]) {
            return kMITLibraryClosedMessageString;
        }
    }
    
    for (MITLibrariesExceptionsTerm *term in self.exceptionsTerm) {
        if ([term isOpenOnDayOfDate:date]) {
            return [term hoursString];
        }
    }
    
    for (MITLibrariesRegularTerm *term in self.regularTerm) {
        if ([term isOpenOnDayOfDate:date]) {
            return [term hoursString];
        }
    }
    
    return kMITLibraryClosedMessageString;
}

- (BOOL)dateFallsInTerm:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [self.dateFormatter dateFromString:self.dates.end];
    
    return [date dateFallsBetweenStartDate:startDate endDate:endDate];
}

- (BOOL)isOpenAtDate:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [self.dateFormatter dateFromString:self.dates.end];
    
    // Check to see if the date even falls within the term
    if (![date dateFallsBetweenStartDate:startDate endDate:endDate])
    {
        return NO;
    }
    
    // Check to see if the date falls within an exception
    for (MITLibrariesExceptionsTerm *term in self.exceptionsTerm) {
        if ([term isOpenOnDate:date]) {
            return YES;
        }
    }
    
    // Check to see if the library is explicitly closed
    for (MITLibrariesClosingsTerm *term in self.closingsTerm) {
        if ([term isClosedOnDate:date]) {
            return NO;
        }
    }
    
    // Check to see if the library is open for the day of the week
    for (MITLibrariesRegularTerm *term in self.regularTerm) {
        if ([term isOpenOnDate:date]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return dateFormatter;
}

@end
