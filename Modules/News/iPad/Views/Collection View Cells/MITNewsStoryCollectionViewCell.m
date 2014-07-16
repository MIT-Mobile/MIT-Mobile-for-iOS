#import "MITNewsStoryCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITAdditions.h"

@interface MITNewsStoryCollectionViewCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@end

#warning 'External' story image size should probably not be hardcoded
static CGSize const MITNewsStoryCellExternalMaximumImageSize = {.width = 133., .height = 34.};

@implementation MITNewsStoryCollectionViewCell {
    BOOL _isExternalStory;
    CGSize _scaledImageSize;
}

@synthesize story = _story;

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.storyImageView cancelCurrentImageLoad];
}

- (void)updateConstraints
{
    [super updateConstraints];

    if (_isExternalStory) {
        _imageHeightConstraint.constant = _scaledImageSize.height;
        _imageWidthConstraint.constant = _scaledImageSize.width;
        
#warning unused
    } else {
      //  _imageHeightConstraint.constant =  _scaledImageSize.height;
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
                idealImageSize = CGSizeMake(1000, 1000);
                _isExternalStory = NO;
            }
            MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:idealImageSize];
            if (representation) {
                imageURL = representation.url;
                
                if (_isExternalStory) {
                    _scaledImageSize = [self scaledSizeForSize:CGSizeMake([representation.width doubleValue], [representation.height doubleValue]) withMaximumSize:MITNewsStoryCellExternalMaximumImageSize];
                    }
#warning used for dynamic height
                /*else {
                    _scaledImageSize = [self scaledSizeForSize:CGSizeMake([representation.width doubleValue], [representation.height doubleValue]) withMaximumSize:CGSizeMake(self.storyImageView.frame.size.width, MAXFLOAT)];

                    CGFloat cellWidth = self.frame.size.width;
                    CGFloat imageHeight = _scaledImageSize.height;
                    _scaledImageSize.height = (cellWidth / _scaledImageSize.width) * imageHeight;
                    _scaledImageSize.width = cellWidth;
                    
                    //NSLayoutConstraint *contraint = [NSLayoutConstraint constraintWithItem:self.storyImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.storyImageView attribute:NSLayoutAttributeWidth multiplier:_scaledImageSize.height / _scaledImageSize.width constant:0.0f];
                   // [self.storyImageView addConstraint:contraint];
                                    }*/
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
            __weak MITNewsStoryCollectionViewCell *weakSelf = self;
            [self.storyImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                MITNewsStoryCollectionViewCell *blockSelf = weakSelf;
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
        [self.storyImageView cancelCurrentImageLoad];
        self.storyImageView.image = nil;
        self.titleLabel.text = nil;
        self.dekLabel.text = nil;
    }
        
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

@end
