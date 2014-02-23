#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITNewsStory.h"

// This should be larger than any size image we are going to run across (hopefully)
CGSize const MITNewsImageLargestImageSize = {.width = 65535.,.height = 65535.};
CGSize const MITNewsImageSmallestImageSize = {.width = 0.,.height = 0.};

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
    CGFloat scale = [[UIScreen mainScreen] scale];
    size.width *= scale;
    size.height *= scale;
    
    NSArray *sortedRepresentations = [[self.representations allObjects] sortedArrayUsingComparator:^NSComparisonResult(MITNewsImageRepresentation *representation1,MITNewsImageRepresentation *representation2) {
        CGFloat diagonal1 = sqrt(pow([representation1.width doubleValue],2.) + pow([representation1.height doubleValue],2.));
        CGFloat diagonal2 = sqrt(pow([representation2.width doubleValue],2.) + pow([representation2.height doubleValue],2.));
        
        return [@(diagonal1) compare:@(diagonal2)];
    }];
    
    if (CGSizeEqualToSize(size, MITNewsImageSmallestImageSize)) {
        return [sortedRepresentations firstObject];
    } else if (CGSizeEqualToSize(size, MITNewsImageLargestImageSize)) {
        return [sortedRepresentations lastObject];
    } else {
        CGFloat targetDiagonal = sqrt(pow(size.width, 2.) + pow(size.height,2.));
        __block CGFloat bestFit = CGFLOAT_MAX;
        __block MITNewsImageRepresentation *selectedRepresentation = nil;
        [sortedRepresentations enumerateObjectsUsingBlock:^(MITNewsImageRepresentation *representation, NSUInteger idx, BOOL *stop) {
            CGFloat diagonal = sqrt(pow([representation.width doubleValue], 2.) + pow([representation.height doubleValue],2.));
            CGFloat difference = fabs(diagonal - targetDiagonal);
            
            if (difference < bestFit) {
                selectedRepresentation = representation;
                bestFit = difference;
            }
        }];
        
        return selectedRepresentation;
    }
}
@end
