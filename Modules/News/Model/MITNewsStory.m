#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsImage.h"


@implementation MITNewsStory

@dynamic author;
@dynamic body;
@dynamic dek;
@dynamic featured;
@dynamic identifier;
@dynamic publishedAt;
@dynamic read;
@dynamic sourceURL;
@dynamic title;
@dynamic topStory;
@dynamic type;
@dynamic category;
@dynamic coverImage;
@dynamic galleryImages;

+ (RKEntityMapping*)objectMapping
{
    RKEntityMapping *storyMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    storyMapping.identificationAttributes = @[@"identifier"];
    [storyMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                       @"source_url" : @"sourceURL",
                                                       @"title" : @"title",
                                                       @"published_at" : @"publishedAt",
                                                       @"author" : @"author",
                                                       @"dek" : @"dek",
                                                       @"featured" : @"featured",
                                                       @"body_html" : @"body",
                                                       @"type" : @"type"}];
    
    RKRelationshipMapping* categoryRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"category"
                                                                                              toKeyPath:@"category"
                                                                                            withMapping:[MITNewsCategory storyObjectMapping]];
    [storyMapping addPropertyMapping:categoryRelationship];
    
    RKRelationshipMapping* coverImageRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cover_image"
                                                                                                toKeyPath:@"coverImage"
                                                                                              withMapping:[MITNewsImage objectMapping]];
    [storyMapping addPropertyMapping:coverImageRelationship];
    
    RKRelationshipMapping* galleryImagesRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"gallery_images"
                                                                                                   toKeyPath:@"galleryImages"
                                                                                                 withMapping:[MITNewsImage objectMapping]];
    [storyMapping addPropertyMapping:galleryImagesRelationship];
    
    return storyMapping;
}

- (NSString *)dek
{
    [self willAccessValueForKey:@"dek"];
    NSString *dek = [self primitiveValueForKey:@"dek"];
    [self didAccessValueForKey:@"dek"];

    dek = [dek stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return dek;
}

- (NSString *)title
{
    [self willAccessValueForKey:@"title"];
    NSString *title = [self primitiveValueForKey:@"title"];
    [self didAccessValueForKey:@"title"];
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return title;
}

@end
