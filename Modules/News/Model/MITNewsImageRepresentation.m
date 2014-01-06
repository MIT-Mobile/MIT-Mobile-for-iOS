#import "MITNewsImageRepresentation.h"
#import "MITNewsImage.h"


@implementation MITNewsImageRepresentation

@dynamic height;
@dynamic width;
@dynamic url;
@dynamic name;
@dynamic image;

+ (NSString*)entityName
{
    return @"NewsImageRep";
}
@end
