#import "StoryImageView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImageRep.h"
#import "MobileRequestOperation.h"

@interface StoryImageView ()
@property (nonatomic, weak) UIActivityIndicatorView *loadingView;

@property (strong) NSData *imageData;
@end

@implementation StoryImageView
- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.opaque = YES;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setImageRep:(NewsImageRep *)newImageRep {
    if (![newImageRep isEqual:_imageRep]) {
        _imageRep = newImageRep;

        self.imageView.image = nil;
        self.imageView.hidden = YES;

        if (self.loadingView) {
            [self.loadingView stopAnimating];
        }
    }
}

- (void)loadImage {
    // show cached image if available
    if (self.imageRep.data) {
        self.imageData = self.imageRep.data;
        [self displayImage];
        // otherwise try to fetch the image from
    } else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    BOOL wasSuccessful = NO;
    
    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    if (!self.imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:nil]; // image is set below
        imageView.frame = self.bounds;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        [self addSubview:imageView];
        self.imageView = imageView;
    }
    
    [self.loadingView stopAnimating];
    
    // don't show imageView if imageData isn't actually a valid image
    if (image) {
        self.imageView.image = image;
        self.imageView.hidden = NO;
        wasSuccessful = YES;
    }
    
    if ([self.delegate respondsToSelector:@selector(storyImageViewDidDisplayImage:)]) {
        [self.delegate storyImageViewDidDisplayImage:self];
    }
    
    return wasSuccessful;
}

- (void)layoutSubviews {
    self.imageView.frame = self.bounds;
    self.loadingView.center = CGPointMake(self.center.x - CGRectGetMidX(self.loadingView.frame),
                                          self.center.y - CGRectGetMidY(self.loadingView.frame));
}

- (void)requestImage {
    NSString *imageURLString = self.imageRep.url;
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithURL:[NSURL URLWithString:imageURLString]
                                                                       parameters:nil];

    __weak StoryImageView *weakSelf = self;
    request.completeBlock = ^(MobileRequestOperation *request, NSData *data, NSString *contentType, NSError *error) {
        StoryImageView *blockSelf = weakSelf;
        if ([blockSelf.imageRep.url isEqualToString:imageURLString]) {
            if (error) {
                blockSelf.imageData = nil;
            } else {
                blockSelf.imageData = data;
                BOOL validImage = [blockSelf displayImage];
                if (validImage) {
                    blockSelf.imageRep.data = data;
                    [CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
                }
            }
        }
    };
    
    self.imageData = nil;
    
    if (!self.loadingView) {
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingView.center = CGPointMake(self.center.x - CGRectGetMidX(loadingView.frame),
                                         self.center.y - CGRectGetMidY(loadingView.frame));
        loadingView.hidesWhenStopped = YES;
        [self addSubview:loadingView];
        self.loadingView = loadingView;
    }

    self.imageView.hidden = YES;
    [self.loadingView startAnimating];
    
    [[MobileRequestOperation defaultQueue] addOperation:request];
}

@end
