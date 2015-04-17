#import <Foundation/Foundation.h>
#import "MITImageScrollView.h"

@interface MITImageScrollView () <UIScrollViewDelegate>
{
    __weak UIImageView *_zoomView;
    CGSize _imageSize;
    CGPoint _pointToCenterAfterResize;
    CGFloat _scaleToRestoreAfterResize;
}

@end

@implementation MITImageScrollView
- (void)awakeFromNib
{
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;        
    }
    return self;
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _zoomView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    _zoomView.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

- (void)resetZoom
{
    CGFloat newScale = self.minimumZoomScale;
    if (self.zoomScale == self.minimumZoomScale) {
        newScale = 2.0;
    }
    [self setZoomScale:newScale animated:YES];
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _zoomView;
}

- (void)displayImage:(UIImage *)image
{
    // clear the previous image
    [_zoomView removeFromSuperview];
    self.zoomScale = 1.0;

    // make a new UIImageView for the new image
    UIImageView *zoomView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:zoomView];
    _zoomView = zoomView;
    
    [self configureForImageSize:image.size];
}

- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.contentSize = imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
                
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / _imageSize.height;   // the scale needed to perfectly fit the image height-wise
    
    self.maximumZoomScale = 2.0;
    CGFloat minScale = MIN(xScale, yScale);
    if (minScale > self.maximumZoomScale) {
         minScale = self.maximumZoomScale;
    }
    self.minimumZoomScale = minScale;
}

#pragma mark - Rotation support
- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:_zoomView];

    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:_zoomView];

    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);

    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

@end