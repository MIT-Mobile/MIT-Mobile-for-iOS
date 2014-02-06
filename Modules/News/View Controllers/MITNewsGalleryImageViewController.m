#import "MITNewsGalleryImageViewController.h"
#import "UIImageView+WebCache.h"

#if CGFLOAT_IS_DOUBLE == 1
#define CGFLOAT_EPSILON DBL_EPSILON
#else
#define CGFLOAT_EPSILON FLT_EPSILON
#endif

@interface MITNewsGalleryImageViewController () <UIScrollViewDelegate>
@property (nonatomic) CGSize imageSize;

@end

@implementation MITNewsGalleryImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.imageURL) {
        [self.imageView setImageWithURL:self.imageURL
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  self.scrollView.contentSize = image.size;

                                  [self setZoomScalesForCurrentBounds];
                                  self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
                              }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.imageView cancelCurrentImageLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Copied from Apple's PhotoScroller sample application
//
- (void)setZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.view.bounds.size;

    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / _imageSize.height;   // the scale needed to perfectly fit the image height-wise

    // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
    BOOL imagePortrait = _imageSize.height > _imageSize.width;
    BOOL phonePortrait = boundsSize.height > boundsSize.width;
    CGFloat minScale = imagePortrait == phonePortrait ? xScale : MIN(xScale, yScale);

    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];

    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minScale > maxScale) {
        minScale = maxScale;
    }

    self.scrollView.maximumZoomScale = maxScale;
    self.scrollView.minimumZoomScale = minScale;
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    CGSize imageSize = self.imageView.image.size;
    CGSize viewBoundsSize = self.view.bounds.size;

    CGFloat horizontalPadding = (viewBoundsSize.width - (self.scrollView.zoomScale * imageSize.width));
    if (horizontalPadding < (0 + CGFLOAT_EPSILON)) {
        horizontalPadding = 0;
    }

    CGFloat verticalPadding = (viewBoundsSize.height - (self.scrollView.zoomScale * imageSize.width));
    if (verticalPadding < (0 + CGFLOAT_EPSILON)) {
        verticalPadding = 0;
    }

    self.leadingContentConstraint.constant = horizontalPadding;
    self.trailingContentConstraint.constant = horizontalPadding;

    self.topContentConstraint.constant = verticalPadding;
    self.topContentConstraint.constant = verticalPadding;
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self.scrollView setNeedsUpdateConstraints];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
