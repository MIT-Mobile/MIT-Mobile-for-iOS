#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsImage.h"


@implementation MITNewsStory

@dynamic body;
@dynamic author;
@dynamic read;
@dynamic featured;
@dynamic identifier;
@dynamic sourceURL;
@dynamic publishedAt;
@dynamic title;
@dynamic topStory;
@dynamic summary;
@dynamic categories;
@dynamic images;

+ (NSString*)entityName
{
    return @"NewsStory";
}

@end
