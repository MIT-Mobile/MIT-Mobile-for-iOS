#import "MITLibrariesLibrary.h"
#import "MITLibrariesTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

NSString *const kMITLibraryClosedMessageString = @"Closed Today";

@implementation MITLibrariesLibrary

+ (RKMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesLibrary class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"phone" : @"phoneNumber",
                                                  @"coordinates": @"coordinateArray"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"name", @"location"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"terms" mapping:[MITLibrariesTerm objectMapping]];
    
    return mapping;
}

- (NSString *)hoursStringForDate:(NSDate *)date
{
    for (MITLibrariesTerm *term in self.terms) {
        if ([term dateFallsInTerm:date]) {
            return [term hoursStringForDate:date];
        }
    }
    return kMITLibraryClosedMessageString;
}

- (BOOL)isOpenAtDate:(NSDate *)date
{
    for (MITLibrariesTerm *term in self.terms) {
        if ([term isOpenAtDate:date]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isOpenOnDayOfDate:(NSDate *)date
{
    for (MITLibrariesTerm *term in self.terms) {
        if ([term isOpenOnDayOfDate:date]) {
            return YES;
        }
    }
    return NO;
}

- (CLLocationCoordinate2D)coordinate
{
    if (self.coordinateArray.count > 1) {
        return CLLocationCoordinate2DMake([self.coordinateArray[1] doubleValue], [self.coordinateArray[0] doubleValue]);
    } else {
        return CLLocationCoordinate2DMake(0, 0);
    }
}

@end
