#import "StoryGalleryViewController.h"
#import "NewsImage.h"
#import "UIKit+MITAdditions.h"

#define STORY_GALLERY_PADDING 10.0

@implementation StoryGalleryViewController

@synthesize images;

- (void)loadView {
    [super loadView];
    // if this isn't implemented, the view is never reloaded after a memory warning
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.backgroundColor = [UIColor whiteColor];
    CGFloat paddedWidth = self.view.frame.size.width - (STORY_GALLERY_PADDING * 2);
    storyImageView = [[StoryImageView alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, STORY_GALLERY_PADDING, paddedWidth, 200)];
    storyImageView.delegate = self;

    captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, 0, paddedWidth, 10)];
    captionLabel.textColor = [UIColor colorWithHexString:@"#202020"];
    captionLabel.font = [UIFont systemFontOfSize:13.0];
    captionLabel.numberOfLines = 0;
    captionLabel.lineBreakMode = UILineBreakModeWordWrap;
    captionLabel.backgroundColor = [UIColor whiteColor];
    captionLabel.opaque = YES;
    
    creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(STORY_GALLERY_PADDING, 0, paddedWidth, 10)];
    creditLabel.textColor = [UIColor colorWithHexString:@"#505050"];
    creditLabel.font = [UIFont systemFontOfSize:11.0];
    creditLabel.numberOfLines = 0;
    creditLabel.lineBreakMode = UILineBreakModeWordWrap;
    creditLabel.backgroundColor = [UIColor whiteColor];
    creditLabel.opaque = YES;
    
    [scrollView addSubview:storyImageView];
    [scrollView addSubview:captionLabel];
    [scrollView addSubview:creditLabel];
    [self.view addSubview:scrollView];

    NSInteger imageCount = [self.images count];
    
    if (imageCount > 0) {
        if (imageCount > 1) {
            UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:
													[NSArray arrayWithObjects:
													 [UIImage imageNamed:MITImageNameUpArrow], 
													 [UIImage imageNamed:MITImageNameDownArrow], 
													 nil]];
            [segmentedControl setMomentary:YES];
            segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
			segmentedControl.frame = CGRectMake(0, 0, 80.0, segmentedControl.frame.size.height);
            [segmentedControl addTarget:self action:@selector(didPressNavButton:) forControlEvents:UIControlEventValueChanged];
            
            UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: segmentedControl];
            self.navigationItem.rightBarButtonItem = segmentBarItem;
            [segmentedControl release];
            [segmentBarItem release];
        }
        imageIndex = 0;

        [self changeImage];
    }
    [scrollView sizeToFit];
}

- (void)viewDidUnload {
    [scrollView release];
    scrollView = nil;
    
    [captionLabel release];
    captionLabel = nil;
    
    [creditLabel release];
    creditLabel = nil;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
    for (NewsImage *anImage in self.images) {
        anImage.fullImage.data = nil;
    }
}

- (void)dealloc {
    for (NewsImage *anImage in self.images) {
        anImage.fullImage.data = nil;
    }
    [super dealloc];
}

- (void)resizeLabelWithFixedWidth:(UILabel *)aLabel {
    CGSize newSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(aLabel.frame.size.width, 2000) lineBreakMode:aLabel.lineBreakMode];
    CGRect frame = aLabel.frame;
    frame.size.height = newSize.height;
    aLabel.frame = frame;
}

- (void)storyImageViewDidDisplayImage:(StoryImageView *)imageView {
    CGSize imageSize = storyImageView.imageView.image.size;
    CGFloat galleryWidth = self.view.frame.size.width - (STORY_GALLERY_PADDING * 2);
    CGFloat ratio = galleryWidth / imageSize.width;
    CGSize scaledSize;
    if (ratio < 1.0) {
        scaledSize = CGSizeMake(galleryWidth, imageSize.height * ratio);
    } else {
        scaledSize = CGSizeMake(galleryWidth, imageSize.height);
    }

    CGRect frame = storyImageView.frame;
    frame.size = scaledSize;
    storyImageView.frame = frame;
    [storyImageView setNeedsLayout];
    
    frame = captionLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(storyImageView.frame) + 3.0);
    captionLabel.frame = frame;
    
    frame = creditLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(captionLabel.frame) + 3.0);
    creditLabel.frame = frame;
    
    CGSize size = scrollView.contentSize;
    size.width = self.view.frame.size.width;
    size.height = ceil(CGRectGetMaxY(creditLabel.frame) + STORY_GALLERY_PADDING);
    scrollView.contentSize = size;
}

- (void)didPressNavButton:(id)sender {
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *theControl = (UISegmentedControl *)sender;
        NSInteger i = theControl.selectedSegmentIndex;
        if (i == 0) {
            imageIndex--;
            if (imageIndex < 0) {
                imageIndex = [self.images count] - 1;
            }
        } else {
            imageIndex++;
            if (imageIndex >= [self.images count]) {
                imageIndex =  0;
            }
        }
        [self changeImage];
    }
}

- (void)changeImage {
    self.title = [NSString stringWithFormat:@"%d of %d", imageIndex + 1, [self.images count]];
	
    NewsImage *anImage = [self.images objectAtIndex:imageIndex];
    CGRect frame = storyImageView.frame;
	CGFloat imageWidth = [anImage.fullImage.width floatValue];
	CGFloat imageHeight = [anImage.fullImage.height floatValue];
    frame.size.height = (frame.size.width >= imageWidth) ? imageHeight : (imageHeight * frame.size.width / imageWidth); // scale height to predict how aspect scaling will affect the image's height
    storyImageView.frame = frame;
    storyImageView.imageRep = anImage.fullImage;
	[storyImageView setNeedsLayout];
    
    captionLabel.text = anImage.caption;
    [self resizeLabelWithFixedWidth:captionLabel];
    creditLabel.text = anImage.credits;
    [self resizeLabelWithFixedWidth:creditLabel];

    frame = captionLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(storyImageView.frame) + 3.0);
    captionLabel.frame = frame;
    
    frame = creditLabel.frame;
    frame.origin.y = ceil(CGRectGetMaxY(captionLabel.frame) + 3.0);
    creditLabel.frame = frame;
	
    [storyImageView loadImage];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

@end
