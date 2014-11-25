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
    
    [self.storyImageView sd_cancelCurrentImageLoad];
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
    _story = story;
    
    if (_story) {
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
        } else {
            self.titleLabel.text = nil;
        }
        
        if (dek) {
            NSError *error = nil;
            NSString *dekContent = [dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
            if (error) {
                DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
                dekContent = dek;
            }
            self.dekLabel.text = dekContent;
        } else {
            self.dekLabel.text = nil;
        }
        
        if (imageURL) {
            MITNewsStory *currentStory = self.story;
            __weak MITNewsStoryCell *weakSelf = self;
            [self.storyImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                MITNewsStoryCell *blockSelf = weakSelf;
                if (blockSelf && (blockSelf->_story == currentStory)) {
                    if (error) {
                        blockSelf.storyImageView.image = nil;
                    }
                }
            }];
        } else {
            self.storyImageView.image = nil;
        }
    } else {
        [self.storyImageView sd_cancelCurrentImageLoad];
        self.storyImageView.image = nil;
        self.titleLabel.text = nil;
        self.dekLabel.text = nil;
    }

    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

#pragma mark UITableViewCell Overrides
- (UIView*)contentView
{
    if (self.contentContainerView) {
        return self.contentContainerView;
    } else {
        return [super contentView];
    }
}
@end
