#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITCoreDataController.h"

@implementation MITMapCategory

@dynamic name;
@dynamic url;
@dynamic identifier;
@dynamic places;
@dynamic children;
@dynamic parent;

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

@end
