#import "MITNewsStoryCell.h"
#import "UIImageView+WebCache.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITAdditions.h"

@interface MITNewsStoryCell ()

@end

@implementation MITNewsStoryCell
@synthesize story = _story;

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.storyImageView cancelCurrentImageLoad];
    self.storyImageView.image = nil;
    self.titleLabel.text = nil;
    self.dekLabel.text = nil;
    _story = nil;
}

- (void)setRepresentedObject:(id)object
{
    [self setStory:object];
}

- (void)setStory:(MITNewsStory *)story
{
    if (![_story isEqual:story]) {
        _story = story;
        
        if (story) {
            __block NSString *title = nil;
            __block NSString *dek = nil;
            __block NSURL *imageURL = nil;
            [_story.managedObjectContext performBlockAndWait:^{
                title = story.title;
                dek = story.dek;
                
                MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:MITNewsImageSmallestImageSize];
                if (representation) {
                    imageURL = representation.url;
                }
            }];
            
            if (title) {
                NSError *error = nil;
                NSString *titleContent = [title stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
                if (!titleContent) {
                    DDLogWarn(@"failed to sanitize title, falling back to the original content: %@",error);
                    titleContent = title;
                }
                
                self.titleLabel.text = titleContent;
            }
            
            if (dek) {
                NSError *error = nil;
                NSString *dekContent = [dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
                if (error) {
                    DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
                    dekContent = dek;
                }
                
                self.dekLabel.text = dekContent;
            }
            
            if (imageURL) {
                [self.storyImageView setImageWithURL:imageURL];
            }
        } else {
            [self.storyImageView cancelCurrentImageLoad];
            self.storyImageView.image = nil;
            self.titleLabel.text = nil;
            self.dekLabel.text = nil;
        }
    }
}
@end
