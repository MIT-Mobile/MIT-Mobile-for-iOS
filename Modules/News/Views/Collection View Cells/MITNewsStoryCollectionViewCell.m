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

// Magic numbers derived from the News Office's front page
static CGSize const MITNewsStoryCellExternalMaximumImageSize = {.width = 133., .height = 34.};

@implementation MITNewsStoryCollectionViewCell {
    BOOL _isExternalStory;
    CGSize _imageSize;
}

@synthesize story = _story;
+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    _story = nil;

    // Reset the image constraints before the cell is reused.
    // If this is not done, UICollectionView will throw constraint
    // failures when a cell is about to be dequeued for reuse.
    // The constraint failures don't seem to affect the app, they just look
    // terrible.
    _imageSize = CGSizeZero;
    [self needsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [self.storyImageView sd_cancelCurrentImageLoad];
}

- (void)updateConstraints
{
    CGSize maximumImageSize = CGSizeZero;
    if (_isExternalStory) {
        maximumImageSize = MITNewsStoryCellExternalMaximumImageSize;
        CGSize imageSize = [self scaledSizeForSize:_imageSize withMaximumSize:maximumImageSize];
        
        self.imageHeightConstraint.constant = imageSize.height;
        self.imageWidthConstraint.constant = imageSize.width;
    }
    
    self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.titleLabel.frame);
    self.dekLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.dekLabel.frame);

    [super updateConstraints];
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
    [self.storyImageView sd_cancelCurrentImageLoad];

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
                idealImageSize = CGSizeMake(512, 512);
                _isExternalStory = NO;
            }

            MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:idealImageSize];
            if (representation) {
                imageURL = representation.url;
                _imageSize = CGSizeMake([representation.width doubleValue], [representation.height doubleValue]);
            } else {
                _imageSize = CGSizeZero;
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
            [self.storyImageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                MITNewsStoryCollectionViewCell *blockSelf = weakSelf;
                // If we still exist...
                if (blockSelf) {
                    // ...and the same story is still active
                    if (blockSelf->_story == currentStory) {
                        if (error) {
                            blockSelf.storyImageView.image = nil;
                        }
                    }
                }
            }];
        } else {
            self.storyImageView.image = nil;
        }
    } else {
        self.storyImageView.image = nil;
        self.titleLabel.text = nil;
        self.dekLabel.text = nil;
    }

    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)commonInit
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1 ) {
        [[self contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
        [self loadHiglightView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)loadHiglightView
{
    self.highlightView = [[UIView alloc] init];
    [self.highlightView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.highlightView.backgroundColor = [UIColor blackColor];
    self.highlightView.alpha = .16;
    [self.contentView addSubview:self.highlightView];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.highlightView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.contentView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0
                                                           constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.highlightView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.contentView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0
                                                           constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.highlightView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.contentView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.highlightView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.contentView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0.0]];
    self.highlightView.hidden = YES;
}

@end
