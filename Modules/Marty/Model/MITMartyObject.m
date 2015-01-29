#import "MITMartyObject.h"


@implementation MITMartyObject

@dynamic created;
@dynamic createdBy;
@dynamic identifier;
@dynamic modified;
@dynamic modifiedBy;
@dynamic name;

+ (RKMapping*)objectMapping
{
    return nil;
}

@end
