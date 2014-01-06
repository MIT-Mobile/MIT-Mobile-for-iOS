#import "MITMapBookmark.h"
#import "MITMapPlace.h"


@implementation MITMapBookmark

@dynamic order;
@dynamic place;

+ (NSString*)entityName
{
    return @"MapBookmark";
}

@end
