#import "MITThumbnailView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "MITTouchstoneRequestOperation.h"

@interface MITThumbnailView ()
- (BOOL)displayImage:(UIImage*)image;
- (BOOL)displayImageWithData:(NSData*)data;
@end

@implementation MITThumbnailView
+ (UIImage *)placeholderImage {
    return [UIImage imageNamed:MITImageNewsImagePlaceholder];
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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

    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;

    // don't show imageView if imageData isn't actually a valid image
    if (image && image.size.width > 0 && image.size.height > 0) {
        if (!self.imageView) {
            self.imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
            [self addSubview:self.imageView];
            self.imageView.frame = self.bounds;
            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        }

        self.imageView.image = image;
        self.imageView.hidden = NO;
        wasSuccessful = YES;
        [self.imageView setNeedsLayout];
    } else {
        self.backgroundColor = [UIColor colorWithPatternImage:[MITThumbnailView placeholderImage]];
    }

    [self setNeedsLayout];
    return wasSuccessful;
}

- (BOOL)displayImageWithData:(NSData*)data
{
    UIImage *image = [[UIImage alloc] initWithData:data];

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
        [[MIT_MobileAppDelegate applicationDelegate] hideNetworkActivityIndicator];

        if (!blockSelf) {
            return;
        } else if ([data isKindOfClass:[NSData class]]) {
            UIImage *image = [UIImage imageWithData:data scale:1.0];

            if (image) {
                blockSelf.imageData = data;

                BOOL validImage = [blockSelf displayImage:image];
                if (validImage) {
                    [blockSelf.delegate thumbnail:blockSelf didLoadData:data];
                }

            } else {
                [blockSelf displayImageWithData:nil];
            }

        } else {
            [blockSelf displayImageWithData:nil]; // will fail to load the image, displays placeholder thumbnail instead
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        MITThumbnailView *blockSelf = weakSelf;

        if (blockSelf) {
            blockSelf.imageData = nil;
            [blockSelf displayImageWithData:nil]; // will fail to load the image, displays placeholder thumbnail instead

            [[MIT_MobileAppDelegate applicationDelegate] hideNetworkActivityIndicator];
        }
    }];

    self.imageData = nil;
    
    if (!self.loadingView) {
        self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.loadingView];
        self.loadingView.center = self.center;
    }

    self.imageView.hidden = YES;
    self.loadingView.hidden = NO;
    [self.loadingView startAnimating];

    [[MIT_MobileAppDelegate applicationDelegate] showNetworkActivityIndicator];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

@end

