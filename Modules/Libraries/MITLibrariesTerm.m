#import "MITLibrariesTerm.h"
#import "MITLibrariesDate.h"
#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesClosingsTerm.h"
#import "MITLibrariesExceptionsTerm.h"

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
    return YES;
}

@end
