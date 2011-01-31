#import "MITThumbnailView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"

@implementation MITThumbnailView

@synthesize imageURL, connection, imageData, loadingView, imageView, delegate;

+ (UIImage *)placeholderImage {
    // TODO: allow placeholders image to be set
    static NSString * const placeholderImageName = @"news/news-placeholder.png";
    static UIImage *placeholderImage = nil;
    if (!placeholderImage) {
        placeholderImage = [[UIImage imageNamed:placeholderImageName] retain];
    }
    return placeholderImage;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        connection = nil;
        imageURL = nil;
        imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithPatternImage:[MITThumbnailView placeholderImage]];
    }
    return self;
}

- (void)loadImage {
    // show cached image if available
    if (self.imageData) {
        [self displayImage];
    }
    // otherwise try to fetch the image from
    else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    BOOL wasSuccessful = NO;
    
    [loadingView stopAnimating];
    loadingView.hidden = YES;
    
    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    // don't show imageView if imageData isn't actually a valid image
    if (image && image.size.width > 0 && image.size.height > 0) {
        if (!imageView) {
            imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
            [self addSubview:imageView];
            imageView.frame = self.bounds;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        }
        
        imageView.image = image;
        imageView.hidden = NO;
        wasSuccessful = YES;
        [imageView setNeedsLayout];
    } else {
        self.backgroundColor = [UIColor colorWithPatternImage:[MITThumbnailView placeholderImage]];
    }
    [self setNeedsLayout];
    
    [image release];
    return wasSuccessful;
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection
    
    // temporary fix to prevent loading of directories as images
    // need news office to improve feed
    // 
    // in the future, should spin off thumbnail as its own Core Data entity with an "not a valid image" flag
    if (self.imageURL == nil) {
        self.backgroundColor = [UIColor colorWithPatternImage:[MITThumbnailView placeholderImage]];
        return;
    }
    
    if ([self.connection isConnected]) {
        return;
    }
    
    if (!self.connection) {
        self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    }
    [self.connection requestDataFromURL:[NSURL URLWithString:self.imageURL] allowCachedResponse:YES];
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showNetworkActivityIndicator];
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.loadingView];
        loadingView.center = self.center;
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
        [self.delegate thumbnail:self didLoadData:data];
    }
    
    self.connection = nil;
    
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideNetworkActivityIndicator];
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    self.imageData = nil;
    [self displayImage]; // will fail to load the image, displays placeholder thumbnail instead
    self.connection = nil;
    
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
    [imageURL release];
    self.delegate = nil;
    [super dealloc];
}

@end

