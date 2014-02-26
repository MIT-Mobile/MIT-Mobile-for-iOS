#import "MITNewsStoryCell.h"
#import "UIImageView+WebCache.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITAdditions.h"

@interface MITNewsStoryCell ()
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@end

#warning 'External' story image size should probably not be hardcoded
static CGSize const MITNewsStoryCellExternalMaximumImageSize = {.width = 133., .height = 34.};

@implementation MITNewsStoryCell {
    BOOL _isExternalStory;
    CGSize _scaledImageSize;
}

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

- (void)updateConstraints
{
    [super updateConstraints];

    if (_isExternalStory) {
        _imageHeightConstraint.constant = _scaledImageSize.height;
        _imageWidthConstraint.constant = _scaledImageSize.width;
    }
}

- (void)setRepresentedObject:(id)object
{
    [self setStory:object];
}

- (CGSize)scaledSizeForSize:(CGSize)targetSize withMaximumSize:(CGSize)maximumSize
{
    if ((targetSize.width > maximumSize.width) || (targetSize.height > maximumSize.height)) {
        CGFloat xScale = maximumSize.width / targetSize.width;
        CGFloat yScale = maximumSize.height / targetSize.height;

        CGFloat scale = MIN(xScale,yScale);
        return CGSizeMake(ceil(targetSize.width * scale), ceil(targetSize.height * scale));
    } else {
        return targetSize;
    }
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


                CGSize idealImageSize = CGSizeZero;
                if ([story.type isEqualToString:@"news_clip"]) {
                    idealImageSize = MITNewsStoryCellExternalMaximumImageSize;
                    _isExternalStory = YES;
                } else {
                    idealImageSize = self.storyImageView.frame.size;
                    _isExternalStory = NO;
                }

                MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:idealImageSize];
                if (representation) {
                    imageURL = representation.url;

                    if (_isExternalStory) {
                        _scaledImageSize = [self scaledSizeForSize:CGSizeMake([representation.width doubleValue], [representation.height doubleValue]) withMaximumSize:MITNewsStoryCellExternalMaximumImageSize];
                    }
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
                [self.contentView setNeedsUpdateConstraints];
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
