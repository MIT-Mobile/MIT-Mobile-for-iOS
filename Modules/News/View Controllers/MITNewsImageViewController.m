#import "MITNewsImageViewController.h"
#import "UIImageView+WebCache.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

static CGSize CGSizeScale(CGSize size, CGFloat xScale,CGFloat yScale) {
    return CGSizeMake(size.width * xScale, size.height * yScale);
}

@interface MITNewsImageViewController () <UIScrollViewDelegate>
@property (nonatomic,readonly) BOOL needsToRecenterImage;

- (void)setNeedsToRecenterImage;
- (void)recenterImageIfNeeded;
@end

@implementation MITNewsImageViewController

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
    self.scrollView.bounces = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.image) {
        // Grab the highest resolution we can get from the
        // current image.
        __block CGSize imageSize = CGSizeZero;
        __block NSURL *imageURL = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsImageRepresentation *imageRepresentation = [self.image bestRepresentationForSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            imageSize.width = [imageRepresentation.width doubleValue];
            imageSize.height = [imageRepresentation.height doubleValue];
            imageURL = imageRepresentation.url;
        }];
        
        CGRect imageFrame = self.imageView.frame;
        imageFrame.size = imageSize;
        
        self.scrollView.contentSize = imageSize;
        [self.imageView setImageWithURL:imageURL
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  [self.imageView sizeToFit];
                                  self.scrollView.contentSize = image.size;
                                  [self updateScrollViewScales];
                                  
                                  [self.imageLoadingIndicator stopAnimating];
                                  self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
                                  
                                  [self setNeedsToRecenterImage];
                                  [self recenterImageIfNeeded];
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
}

#pragma mark Properties
- (void)setNeedsToRecenterImage
{
    self->_needsToRecenterImage = YES;
}

- (MITNewsImage*)image
{
    if (_image) {
        if (_image.managedObjectContext != self.managedObjectContext) {
            [self.managedObjectContext performBlockAndWait:^{
                _image = (MITNewsImage*)[self.managedObjectContext objectWithID:[_image objectID]];
            }];
        }
    }
    
    return _image;
}

- (void)updateScrollViewScales
{
    CGSize imageSize = self.imageView.image.size;
    CGSize viewBoundsSize = self.view.bounds.size;

    CGFloat minimumZoomScale = fmin((viewBoundsSize.width / imageSize.width),
                                    (viewBoundsSize.height / imageSize.height));

    if (minimumZoomScale > 1) {
        self.scrollView.minimumZoomScale = 1;
    } else {
        self.scrollView.minimumZoomScale = minimumZoomScale;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setNeedsToRecenterImage];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setNeedsToRecenterImage];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self recenterImageIfNeeded];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self recenterImageIfNeeded];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)recenterImageIfNeeded
{
    if (self.needsToRecenterImage) {
        CGSize boundsSize = self.scrollView.bounds.size;
        CGRect contentsFrame = self.imageView.frame;
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
        } else {
            contentsFrame.origin.x = 0.0f;
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
        } else {
            contentsFrame.origin.y = 0.0f;
        }
        
        self.imageView.frame = contentsFrame;
    }
}

@end
