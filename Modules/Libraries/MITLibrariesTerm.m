#import "MITLibrariesTerm.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesDate.h"
#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesClosingsTerm.h"
#import "MITLibrariesExceptionsTerm.h"
#import "Foundation+MITAdditions.h"
#import "MITLibrariesTermProtocol.h"

static NSString * const MITLibraryTermCoderKeyName = @"MITLibraryTermCoderKeyName";
static NSString * const MITLibraryTermCoderKeyDates = @"MITLibraryTermCoderKeyDates";
static NSString * const MITLibraryTermCoderKeyRegularTerm = @"MITLibraryTermCoderKeyRegularTerm";
static NSString * const MITLibraryTermCoderKeyClosingsTerm = @"MITLibraryTermCoderKeyClosingsTerm";
static NSString * const MITLibraryTermCoderKeyExceptionsTerm = @"MITLibraryTermCoderKeyExceptionsTerm";

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
 
    NSDate *startDate = [[self.dateFormatter dateFromString:self.dates.start] startOfDay];
    NSDate *endDate = [[self.dateFormatter dateFromString:self.dates.end] endOfDay];
 
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
    
    NSMutableArray *exceptionsAndClosings = [[NSMutableArray alloc] initWithCapacity:self.closingsTerm.count + self.exceptionsTerm.count];
    [exceptionsAndClosings addObjectsFromArray:self.closingsTerm];
    [exceptionsAndClosings addObjectsFromArray:self.exceptionsTerm];
    
    [exceptionsAndClosings sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        id<MITLibrariesTermProtocol> firstTerm = obj1;
        id<MITLibrariesTermProtocol> secondTerm = obj2;
        return [firstTerm.dates.startDate compare:secondTerm.dates.startDate];
    }];
    
    for (id<MITLibrariesTermProtocol> term in exceptionsAndClosings) {
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
            return [term.hours hoursRangesString];
        }
    }
    
    for (MITLibrariesRegularTerm *term in self.regularTerm) {
        if ([term isOpenOnDayOfDate:date]) {
            return [term.hours hoursRangesString];
        }
    }
    
    return kMITLibraryClosedMessageString;
}

- (BOOL)dateFallsInTerm:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [[self.dateFormatter dateFromString:self.dates.start] startOfDay];
    NSDate *endDate = [[self.dateFormatter dateFromString:self.dates.end] endOfDay];
    
    return [date dateFallsBetweenStartDate:startDate endDate:endDate];
}

- (BOOL)isOpenAtDate:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [[self.dateFormatter dateFromString:self.dates.start] startOfDay];
    NSDate *endDate = [[self.dateFormatter dateFromString:self.dates.end] endOfDay];
    
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

- (BOOL)isOpenOnDayOfDate:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *startDate = [[self.dateFormatter dateFromString:self.dates.start] startOfDay];
    NSDate *endDate = [[self.dateFormatter dateFromString:self.dates.end] endOfDay];
    
    // Check to see if the date even falls within the term
    if (![date dateFallsBetweenStartDate:startDate endDate:endDate])
    {
        return NO;
    }
    
    // Check to see if the date falls within an exception
    for (MITLibrariesExceptionsTerm *term in self.exceptionsTerm) {
        if ([term isOpenOnDayOfDate:date]) {
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
        if ([term isOpenOnDayOfDate:date]) {
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

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:MITLibraryTermCoderKeyName];
        self.dates = [aDecoder decodeObjectForKey:MITLibraryTermCoderKeyDates];
        self.regularTerm = [aDecoder decodeObjectForKey:MITLibraryTermCoderKeyRegularTerm];
        self.closingsTerm = [aDecoder decodeObjectForKey:MITLibraryTermCoderKeyClosingsTerm];
        self.exceptionsTerm = [aDecoder decodeObjectForKey:MITLibraryTermCoderKeyExceptionsTerm];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:MITLibraryTermCoderKeyName];
    [aCoder encodeObject:self.dates forKey:MITLibraryTermCoderKeyDates];
    [aCoder encodeObject:self.regularTerm forKey:MITLibraryTermCoderKeyRegularTerm];
    [aCoder encodeObject:self.closingsTerm forKey:MITLibraryTermCoderKeyClosingsTerm];
    [aCoder encodeObject:self.exceptionsTerm forKey:MITLibraryTermCoderKeyExceptionsTerm];
}

@end
