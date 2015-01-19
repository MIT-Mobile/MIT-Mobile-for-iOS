#import "MITLibrariesLibrary.h"
#import "MITLibrariesTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

NSString *const kMITLibraryClosedMessageString = @"Closed Today";

static NSString * const MITLibraryCoderKeyIdentifier = @"MITLibraryCoderKeyIdentifier";
static NSString * const MITLibraryCoderKeyName = @"MITLibraryCoderKeyName";
static NSString * const MITLibraryCoderKeyURL = @"MITLibraryCoderKeyURL";
static NSString * const MITLibraryCoderKeyLocation = @"MITLibraryCoderKeyLocation";
static NSString * const MITLibraryCoderKeyPhoneNumber = @"MITLibraryCoderKeyPhoneNumber";
static NSString * const MITLibraryCoderKeyTerms = @"MITLibraryCoderKeyTerms";
static NSString * const MITLibraryCoderKeyCoordinateArray = @"MITLibraryCoderKeyCoordinateArray";

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

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.identifier = [aDecoder decodeObjectForKey:MITLibraryCoderKeyIdentifier];
        self.name = [aDecoder decodeObjectForKey:MITLibraryCoderKeyName];
        self.url = [aDecoder decodeObjectForKey:MITLibraryCoderKeyURL];
        self.location = [aDecoder decodeObjectForKey:MITLibraryCoderKeyLocation];
        self.phoneNumber = [aDecoder decodeObjectForKey:MITLibraryCoderKeyPhoneNumber];
        self.terms = [aDecoder decodeObjectForKey:MITLibraryCoderKeyTerms];
        self.coordinateArray = [aDecoder decodeObjectForKey:MITLibraryCoderKeyCoordinateArray];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.identifier forKey:MITLibraryCoderKeyIdentifier];
    [aCoder encodeObject:self.name forKey:MITLibraryCoderKeyName];
    [aCoder encodeObject:self.url forKey:MITLibraryCoderKeyURL];
    [aCoder encodeObject:self.location forKey:MITLibraryCoderKeyLocation];
    [aCoder encodeObject:self.phoneNumber forKey:MITLibraryCoderKeyPhoneNumber];
    [aCoder encodeObject:self.terms forKey:MITLibraryCoderKeyTerms];
    [aCoder encodeObject:self.coordinateArray forKey:MITLibraryCoderKeyCoordinateArray];
}

@end
