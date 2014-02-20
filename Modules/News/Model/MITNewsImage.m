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
                                                       @"description" : @"descriptionText"}];
    
    RKRelationshipMapping* imageRepresentationMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"representations"
                                                                                                    toKeyPath:@"representations"
                                                                                                  withMapping:[MITNewsImageRepresentation  objectMapping]];
    [imageMapping addPropertyMapping:imageRepresentationMapping];
    return imageMapping;
}

- (MITNewsImageRepresentation*)bestRepresentationForSize:(CGSize)size
{
    NSMutableArray *sortedRepresentations = [[[self.representations allObjects] sortedArrayUsingComparator:^NSComparisonResult(MITNewsImageRepresentation *representation1,MITNewsImageRepresentation *representation2) {
        CGFloat area1 = [representation1.width doubleValue] * [representation1.height doubleValue];
        CGFloat area2 = [representation2.width doubleValue] * [representation2.height doubleValue];
        
        return [@(area1) compare:@(area2)];
    }] mutableCopy];

#warning potentially ugly behavior when the height or width of the size is really large (height * width >= CGFLOAT_MAX)
    CGFloat targetArea = size.width * size.height;
    [sortedRepresentations sortUsingComparator:^NSComparisonResult(MITNewsImageRepresentation *representation1,MITNewsImageRepresentation *representation2) {
        CGFloat distance1 = ([representation1.width doubleValue] * [representation1.height doubleValue]) - targetArea;
        CGFloat distance2 = ([representation2.width doubleValue] * [representation2.height doubleValue]) - targetArea;
        
        if (distance1 < 0) {
            distance1 = CGFLOAT_MAX;
        }
        
        if (distance2 < 0) {
            distance1 = CGFLOAT_MAX;
        }
        
        return [@(distance1) compare:@(distance2)];
    }];
    
    return [sortedRepresentations firstObject];
}
@end
