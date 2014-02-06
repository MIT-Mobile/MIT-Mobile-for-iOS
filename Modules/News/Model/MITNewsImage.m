#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITNewsStory.h"


@implementation MITNewsImage

@dynamic caption;
@dynamic credits;
@dynamic descriptionText;
@dynamic representations;
@dynamic gallery;
@dynamic cover;

+ (RKObjectMapping*)objectMapping
{
    RKEntityMapping *imageMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [imageMapping addAttributeMappingsFromDictionary:@{@"caption" : @"caption",
                                                       @"credits" : @"credits",
                                                       @"description" : @"description"}];
    
    RKRelationshipMapping* imageRepresentationMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"representations"
                                                                                                    toKeyPath:@"representations"
                                                                                                  withMapping:[MITNewsImageRepresentation  objectMapping]];
    [imageMapping addPropertyMapping:imageRepresentationMapping];
    return imageMapping;
}

- (MITNewsImageRepresentation*)bestRepresentationForSize:(CGSize)size
{
#warning Add logic for selecting the best fitting image (instead of just the smallest)
    NSArray *sortedRepresentations = [[self.representations allObjects] sortedArrayUsingComparator:^NSComparisonResult(MITNewsImageRepresentation *representation1,MITNewsImageRepresentation *representation2) {
        CGFloat area1 = [representation1.width doubleValue] * [representation2.height doubleValue];
        CGFloat area2 = [representation2.width doubleValue] * [representation2.height doubleValue];
        
        return [@(area1) compare:@(area2)];
    }];
    
    return [sortedRepresentations firstObject];
}
@end
