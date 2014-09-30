#import "MITLibrariesLibrary.h"
#import "MITLibrariesTerm.h"

@implementation MITLibrariesLibrary

+ (RKMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesLibrary class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"phone" : @"phoneNumber"}];
    [mapping addAttributeMappingsFromArray:@[@"url", @"name", @"location"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"terms" mapping:[MITLibrariesTerm objectMapping]];
    
    return mapping;
}

- (NSString *)hoursStringForDate:(NSDate *)date
{
    return @"8:00am - 10:00pm";
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

@end
