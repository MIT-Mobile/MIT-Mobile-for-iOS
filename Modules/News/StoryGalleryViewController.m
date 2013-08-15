#import "StoryGalleryViewController.h"
#import "NewsImage.h"
#import "UIKit+MITAdditions.h"

#define STORY_GALLERY_PADDING 10.0

@interface StoryGalleryViewController ()
@property (nonatomic,weak) UIScrollView *scrollView;
@property (nonatomic,weak) UILabel *captionLabel;
@property (nonatomic,weak) UILabel *creditLabel;
@property (nonatomic,weak) StoryImageView *storyImageView;

@property NSInteger imageIndex;

@end

@implementation StoryGalleryViewController
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView = scrollView;

    CGFloat paddedWidth = self.view.frame.size.width - (STORY_GALLERY_PADDING * 2);
    StoryImageView *storyImageView = [[StoryImageView alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, STORY_GALLERY_PADDING, paddedWidth, 200)];
    storyImageView.delegate = self;
    self.storyImageView = storyImageView;

    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, 0, paddedWidth, 10)];
    captionLabel.textColor = [UIColor colorWithHexString:@"#202020"];
    captionLabel.font = [UIFont systemFontOfSize:13.0];
    captionLabel.numberOfLines = 0;
    captionLabel.lineBreakMode = UILineBreakModeWordWrap;
    captionLabel.backgroundColor = [UIColor whiteColor];
    captionLabel.opaque = YES;
    self.captionLabel = captionLabel;

    UILabel *creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, 0, paddedWidth, 10)];
    creditLabel.textColor = [UIColor colorWithHexString:@"#505050"];
    creditLabel.font = [UIFont systemFontOfSize:11.0];
    creditLabel.numberOfLines = 0;
    creditLabel.lineBreakMode = UILineBreakModeWordWrap;
    creditLabel.backgroundColor = [UIColor whiteColor];
    creditLabel.opaque = YES;
    self.creditLabel = creditLabel;

    [scrollView addSubview:storyImageView];
    [scrollView addSubview:captionLabel];
    [scrollView addSubview:creditLabel];
    [self.view addSubview:scrollView];

    NSInteger imageCount = [self.images count];
    
    if (imageCount > 0) {
        if (imageCount > 1) {
            UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:@[[UIImage imageNamed:MITImageNameUpArrow],
                                                                                               [UIImage imageNamed:MITImageNameDownArrow]]];
            [segmentedControl setMomentary:YES];
            segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
			segmentedControl.frame = CGRectMake(0, 0, 80.0, segmentedControl.frame.size.height);
            [segmentedControl addTarget:self action:@selector(didPressNavButton:) forControlEvents:UIControlEventValueChanged];
            
            UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentedControl];
            self.navigationItem.rightBarButtonItem = segmentBarItem;
        }
        self.imageIndex = 0;

        [self changeImage];
    }
    [scrollView sizeToFit];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
    for (NewsImage *anImage in self.images) {
        anImage.fullImage.data = nil;
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    for (NewsImage *anImage in self.images) {
        anImage.fullImage.data = nil;
    }
}

- (void)resizeLabelWithFixedWidth:(UILabel *)aLabel {
    CGSize newSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(aLabel.frame.size.width, 2000) lineBreakMode:aLabel.lineBreakMode];
    CGRect frame = aLabel.frame;
    frame.size.height = newSize.height;
    aLabel.frame = frame;
}

- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView {
    CGSize imageSize = self.storyImageView.imageView.image.size;
    CGFloat galleryWidth = self.view.frame.size.width - (STORY_GALLERY_PADDING * 2);
    CGFloat ratio = galleryWidth / imageSize.width;
    CGSize scaledSize;
    if (ratio < 1.0) {
        scaledSize = CGSizeMake(galleryWidth, imageSize.height * ratio);
    } else {
        scaledSize = CGSizeMake(galleryWidth, imageSize.height);
    }

    CGRect frame = self.storyImageView.frame;
    frame.size = scaledSize;
    self.storyImageView.frame = frame;
    [self.storyImageView setNeedsLayout];
    
    frame = self.captionLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(self.storyImageView.frame) + 3.0);
    self.captionLabel.frame = frame;
    
    frame = self.creditLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(self.captionLabel.frame) + 3.0);
    self.creditLabel.frame = frame;
    
    CGSize size = self.scrollView.contentSize;
    size.width = self.view.frame.size.width;
    size.height = ceil(CGRectGetMaxY(self.creditLabel.frame) + STORY_GALLERY_PADDING);
    self.scrollView.contentSize = size;
}

- (void)didPressNavButton:(id)sender {
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
        if (i == 0) {
            self.imageIndex += 1;
            if (self.imageIndex < 0) {
                self.imageIndex = [self.images count] - 1;
            }
        } else {
            self.imageIndex++;
            if (self.imageIndex >= [self.images count]) {
                self.imageIndex =  0;
            }
        }
        [self changeImage];
    }
}

- (void)changeImage {
    self.title = [NSString stringWithFormat:@"%d of %d", self.imageIndex + 1, [self.images count]];
	
    NewsImage *anImage = self.images[self.imageIndex];
    CGRect frame = self.storyImageView.frame;
	CGFloat imageWidth = [anImage.fullImage.width floatValue];
	CGFloat imageHeight = [anImage.fullImage.height floatValue];
    frame.size.height = (frame.size.width >= imageWidth) ? imageHeight : (imageHeight * frame.size.width / imageWidth); // scale height to predict how aspect scaling will affect the image's height
    self.storyImageView.frame = frame;
    self.storyImageView.imageRep = anImage.fullImage;
    
    self.captionLabel.text = anImage.caption;
    [self resizeLabelWithFixedWidth:self.captionLabel];
    self.creditLabel.text = anImage.credits;
    [self resizeLabelWithFixedWidth:self.creditLabel];

    frame = self.captionLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(self.storyImageView.frame) + 3.0);
    self.captionLabel.frame = frame;
    
    frame = self.creditLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(self.captionLabel.frame) + 3.0);
    self.creditLabel.frame = frame;
    
}

- (BOOL)shouldAutorotate {
    return NO;
}


@end
