#import "MITNewsImageRepresentation.h"
#import "MITNewsImage.h"


@implementation MITNewsImageRepresentation

@dynamic height;
@dynamic width;
@dynamic url;
@dynamic images;

+ (RKObjectMapping*)objectMapping
{
    RKEntityMapping *imageRepresentationMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    imageRepresentationMapping.identificationAttributes = @[@"url"] ;
    [imageRepresentationMapping addAttributeMappingsFromDictionary:@{@"url" : @"url",
                                                                     @"width" : @"width",
                                                                     @"height" : @"height"}];
    return imageRepresentationMapping;
}
@end
