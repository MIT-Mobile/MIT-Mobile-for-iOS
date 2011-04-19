#import "StoryImageView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImageRep.h"

@implementation StoryImageView

@synthesize delegate, imageRep, imageData, loadingView, imageView;

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        connection = nil;
        imageRep = nil;
        imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setImageRep:(NewsImageRep *)newImageRep {
    if (![newImageRep isEqual:imageRep]) {
        [imageRep release];
        imageRep = [newImageRep retain];
        imageView.image = nil;
        imageView.hidden = YES;
        if ([connection isConnected]) {
            [connection cancel];
            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate hideNetworkActivityIndicator];
        }
        if (self.loadingView) {
            [self.loadingView stopAnimating];
            self.loadingView.hidden = YES;
        }
    }
}

- (void)loadImage {
    // show cached image if available
    if (imageRep.data) {
        self.imageData = imageRep.data;
        [self displayImage];
        // otherwise try to fetch the image from
    } else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    BOOL wasSuccessful = NO;
    
    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
        [self addSubview:imageView];
        imageView.frame = self.bounds;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    }
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;
    
    // don't show imageView if imageData isn't actually a valid image
    if (image) {
        imageView.image = image;
        imageView.hidden = NO;
        wasSuccessful = YES;
    }
    
    if ([self.delegate respondsToSelector:@selector(storyImageViewDidDisplayImage:)]) {
        [self.delegate storyImageViewDidDisplayImage:self];
    }
    
    [image release];
    return wasSuccessful;
}

- (void)layoutSubviews {
    imageView.frame = self.bounds;
    if (self.loadingView) {
        loadingView.center = CGPointMake(self.center.x - loadingView.frame.size.width / 2, self.center.y - loadingView.frame.size.height / 2);
    }
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection
    
    if ([[imageRep.url pathExtension] length] == 0) {
        return;
    }
    
    if ([connection isConnected]) {
        return;
    }
    
    if (!connection) {
        connection = [[ConnectionWrapper alloc] initWithDelegate:self];
    }
    [connection requestDataFromURL:[NSURL URLWithString:imageRep.url] allowCachedResponse:YES];
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.loadingView];
        loadingView.center = CGPointMake(self.center.x - loadingView.frame.size.width / 2, self.center.y - loadingView.frame.size.height / 2);
    }
    imageView.hidden = YES;
    loadingView.hidden = NO;
    [loadingView startAnimating];
}

// ConnectionWrapper delegate
- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    // TODO: If memory usage becomes a concern, convert images to PNG using UIImagePNGRepresentation(). PNGs use considerably less RAM.
    self.imageData = data;
    BOOL validImage = [self displayImage];
    if (validImage) {
        imageRep.data = data;
        [CoreDataManager saveData];
    }
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

- (void)dealloc {
	[connection cancel];
    [connection release];
    connection = nil;
    [imageData release];
    imageData = nil;
    [loadingView release];
    [imageView release];
    [super dealloc];
}

@end
