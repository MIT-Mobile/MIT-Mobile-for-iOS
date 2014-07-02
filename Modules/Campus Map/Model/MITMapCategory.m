#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITCoreDataController.h"
#import "MITMapSearch.h"

@implementation MITMapCategory

@dynamic name;
@dynamic url;
@dynamic identifier;
@dynamic places;
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
    return [NSString stringWithFormat:@"map/map_category_%@", self.identifier];
}

@end
