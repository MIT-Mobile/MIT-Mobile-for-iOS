#import "MITMobiusImage.h"
#import "MITMobiusResource.h"
#import "MITMobiusResourceDataSource.h"


@implementation MITMobiusImage

@dynamic identifier;
@dynamic filename;
@dynamic resource;

+ (RKMapping*)objectMapping {
    RKEntityMapping *objectMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [objectMapping addAttributeMappingsFromDictionary:@{@"_id" : @"identifier",
                                                        @"filename" : @"filename"}];

    return objectMapping;
}

- (NSURL*)URLForImageWithSize:(MITMobiusImageSize)imageSize
{
    NSURL *serverURL = [MITMobiusResourceDataSource defaultServerURL];

    NSMutableString *imagePath = [[NSMutableString alloc] initWithFormat:@"image/%@",self.identifier];

    switch (imageSize) {
        case MITMobiusImageSmall: {
            [imagePath appendString:@"?size=small"];
        } break;

        case MITMobiusImageMedium: {
            [imagePath appendString:@"?size=medium"];
        } break;

        case MITMobiusImageLarge: {
            [imagePath appendString:@"?size=large"];
        } break;

        case MITMobiusImageOriginal:
            break;
    }

    return [NSURL URLWithString:imagePath relativeToURL:serverURL];
}

@end
