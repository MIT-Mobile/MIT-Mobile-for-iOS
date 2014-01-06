#import "MITMapPlaceContent.h"
#import "MITMapPlace.h"


@implementation MITMapPlaceContent

@dynamic url;
@dynamic name;
@dynamic building;

+ (NSString*)entityName
{
    return @"MapPlaceContent";
}

@end
