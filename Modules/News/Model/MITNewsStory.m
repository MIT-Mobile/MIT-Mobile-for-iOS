#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsImage.h"
#import "MITAdditions.h"

@interface MITNewsStory ()
@property (nonatomic,copy) NSString *dekText;
@property (nonatomic,copy) NSString *titleText;
@end

@implementation MITNewsStory
@synthesize dekText = _dekText;
@synthesize titleText = _titleText;

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
                                                                                            withMapping:[MITNewsCategory objectMapping]];
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

- (void)setDek:(NSString *)dek
{
    [self willChangeValueForKey:@"dek"];
    [self willChangeValueForKey:@"dekText"];

    [self setPrimitiveValue:dek forKey:@"dek"];
    _dekText = nil;

    [self didChangeValueForKey:@"dek"];
    [self didChangeValueForKey:@"dekText"];
}

- (void)setTitle:(NSString *)title
{
    [self willChangeValueForKey:@"title"];
    [self willChangeValueForKey:@"titleText"];

    [self setPrimitiveValue:title forKey:@"title"];
    _titleText = nil;

    [self didChangeValueForKey:@"title"];
    [self didChangeValueForKey:@"titleText"];
}

- (NSString*)dekText
{
    if (!_dekText) {
        NSError *error = nil;
        NSString *string = [self.dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];

        if (!string) {
            if (error) {
                DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
            }

            _dekText = self.dek;
        } else {
            _dekText = string;
        }
    }

    return _dekText;
}

- (NSString*)titleText
{
    if (!_titleText) {
        NSError *error = nil;
        NSString *string = [self.title stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];

        if (!string) {
            if (error) {
                DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
            }
            
            _titleText = self.title;
        } else {
            _titleText = string;
        }
    }

    return _titleText;
}

@end
