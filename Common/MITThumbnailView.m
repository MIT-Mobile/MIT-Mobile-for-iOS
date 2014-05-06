#import "MITThumbnailView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "MITTouchstoneRequestOperation.h"

@interface MITThumbnailView ()
- (BOOL)displayImage:(UIImage*)image;
- (BOOL)displayImageWithData:(NSData*)data;
@end

@implementation MITThumbnailView

@synthesize imageURL, imageData, loadingView, imageView, delegate;

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
        [self displayImageWithData:self.imageData];
    } else {
        [self requestImage];
    }
}

- (BOOL)displayImage:(UIImage*)image
{
    BOOL wasSuccessful = NO;

    [loadingView stopAnimating];
    loadingView.hidden = YES;

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

- (BOOL)displayImageWithData:(NSData*)data
{
    UIImage *image = [[UIImage alloc] initWithData:imageData];

    if (!data) {
        return [self displayImage:nil];
    } else if (image) {
        self.imageData = data;
        return [self displayImage:image];
    } else {
        return NO;
    }
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

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.imageURL]];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    __weak MITThumbnailView *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSData *data) {
        MITThumbnailView *blockSelf = weakSelf;

        if (!blockSelf) {
            return;
        } else if ([data isKindOfClass:[NSData class]]) {
            UIImage *image = [UIImage imageWithData:data scale:1.0];

            if (image) {
                blockSelf.imageData = data;

                BOOL validImage = [blockSelf displayImage:image];
                if (validImage) {
                    [self.delegate thumbnail:blockSelf didLoadData:data];
                }

                MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate hideNetworkActivityIndicator];
            }
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        MITThumbnailView *blockSelf = weakSelf;

        if (blockSelf) {
            blockSelf.imageData = nil;
            [blockSelf displayImageWithData:nil]; // will fail to load the image, displays placeholder thumbnail instead

            MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate hideNetworkActivityIndicator];
        }
    }];

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

- (void)dealloc {
    [imageData release];
    imageData = nil;
    [loadingView release];
    [imageView release];
    [imageURL release];
    self.delegate = nil;
    [super dealloc];
}

@end

