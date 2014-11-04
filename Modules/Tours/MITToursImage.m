#import "MITToursImage.h"
#import "MITToursImageRepresentation.h"
#import "MITToursStop.h"

@implementation MITToursImage

@dynamic representations;
@dynamic stop;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
       [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"representations" toKeyPath:@"representations" withMapping:[MITToursImageRepresentation objectMapping]]];
    
    return mapping;
}

- (NSString *)thumbnailURL
{
    NSString *imageURL = nil;
    NSInteger minWidth = NSIntegerMax;
    for (MITToursImageRepresentation *representation in self.representations) {
        NSInteger width = [representation.width integerValue];
        if (width < minWidth) {
            imageURL = representation.url;
            minWidth = width;
        }
    }
    return imageURL;
}

- (NSString *)fullImageURL
{
    NSString *imageURL = nil;
    NSInteger maxWidth = 0;
    for (MITToursImageRepresentation *representation in self.representations) {
        NSInteger width = [representation.width integerValue];
        if (width > maxWidth) {
            imageURL = representation.url;
            maxWidth = width;
        }
    }
    return imageURL;
}

@end
