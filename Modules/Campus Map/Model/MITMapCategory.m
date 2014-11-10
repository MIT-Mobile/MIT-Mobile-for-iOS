#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITCoreDataController.h"
#import "MITMapSearch.h"
#import "MITMapPlaceContent.h"

@implementation MITMapCategory

@dynamic name;
@dynamic url;
@dynamic identifier;
@dynamic places;
@dynamic placeContents;
@dynamic children;
@dynamic parent;
@dynamic search;

- (NSString*)canonicalName
{
    NSMutableArray *components = [[NSMutableArray alloc] init];
    MITMapCategory *category = self;

    while (category) {
        [components insertObject:category.name
                         atIndex:0];
        category = category.parent;
    }

    return [components componentsJoinedByString:@","];
}

- (NSString *)iconName
{
    return [NSString stringWithFormat:@"map-category-%@", self.identifier];
}

- (NSString *)sectionIndexTitle
{
    NSString *title;
    if ([self.identifier isEqualToString:@"m"] || [self.identifier isEqualToString:@"1_999"]) {
        title = @"#";
    } else {
        title = [[self.identifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"] uppercaseString];
    }
    return [NSString stringWithFormat:@" %@ ", title];
}

- (NSArray *)allPlaces
{
    NSMutableSet *places = [NSMutableSet set];
    for (MITMapPlaceContent *placeContent in self.placeContents) {
        [places addObject:placeContent.building];
    }
    [places unionSet:self.places];
    return [places sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)]]];
}

@end
