#import "MITLibrariesTerm.h"
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

- (NSString *)hoursStringForDate:(NSDate *)date
{
    return @"8:00am - 10:00pm";
}

- (BOOL)isOpenAtDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *startDate = [dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [dateFormatter dateFromString:self.dates.end];
    
    // Check to see if the date even falls within the term
    if (![date dateFallsBetweenStartDate:startDate endDate:endDate])
    {
        return NO;
    }
    
    // Check to see if the date falls within an exception
    for (MITLibrariesExceptionsTerm *term in self.exceptionsTerm) {
        if ([term isOpenAtDate:date]) {
            return YES;
        }
    }
    
    // Check to see if the library is explicitly closed
    for (MITLibrariesClosingsTerm *term in self.closingsTerm) {
        if ([term isClosedAtDate:date]) {
            return NO;
        }
    }
    
    // Check to see if the library is open for the day of the week
    for (MITLibrariesRegularTerm *term in self.regularTerm) {
        if ([term isOpenAtDate:date]) {
            return YES;
        }
    }
    
    return NO;
}

@end
