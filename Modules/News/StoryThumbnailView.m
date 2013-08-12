#import "StoryThumbnailView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImageRep.h"
#import "MobileRequestOperation.h"

@interface StoryThumbnailView ()
@property (nonatomic, weak) UIActivityIndicatorView *loadingView;
@property (strong) NSData *imageData;

+ (UIImage *)placeholderImage;

@end


@implementation StoryThumbnailView
+ (UIImage *)placeholderImage {
    static NSString * const placeholderImageName = @"news/news-placeholder.png";
    static UIImage *placeholderImage = nil;
    if (!placeholderImage) {
        placeholderImage = [UIImage imageNamed:placeholderImageName];
    }
    return placeholderImage;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
    }
    return self;
}

- (void)setImageRep:(NewsImageRep *)newImageRep {
    if (![newImageRep isEqual:_imageRep]) {
        _imageRep = newImageRep;
        self.imageView.image = nil;
        self.imageView.hidden = YES;

        [self.loadingView stopAnimating];

        if (self.imageRep) {
            self.backgroundColor = [UIColor colorWithWhite:0.60 alpha:1.0];
        } else {
            self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
        }

    }
}

- (void)loadImage {
    // show cached image if available
    if (self.imageRep.data) {
        self.imageData = self.imageRep.data;
        [self displayImage];
    } else {
        [self requestImage];
    }
}

- (BOOL)displayImage {
    BOOL wasSuccessful = NO;
    
    [self.loadingView stopAnimating];

    UIImage *image = [[UIImage alloc] initWithData:self.imageData];
    
    // don't show imageView if imageData isn't actually a valid image
    if (image && image.size.width > 0 && image.size.height > 0) {
        if (!self.imageView) {
            UIImageView *imageView = [[UIImageView alloc] init]; // image is set below
            imageView.frame = self.bounds;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            [self addSubview:imageView];
            self.imageView = imageView;
        }

        self.imageView.image = image;
        self.imageView.hidden = NO;
        wasSuccessful = YES;
    } else {
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
    }

    [self setNeedsLayout];
    return wasSuccessful;
}

- (void)requestImage {
    // TODO: don't attempt to load anything if there's no net connection

    // temporary fix to prevent loading of directories as images
    // need news office to improve feed
    // 
    // in the future, should spin off thumbnail as its own Core Data entity with an "not a valid image" flag
    if ([[self.imageRep.url pathExtension] length] == 0) {
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
        return;
    }
    
    NSURL *imageURL = [[NSURL alloc] initWithString:self.imageRep.url];
    MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithURL:imageURL parameters:nil];

    __weak StoryThumbnailView *weakSelf = self;
    request.completeBlock = ^(MobileRequestOperation *request, NSData *data, NSString *contentType, NSError *error) {
        StoryThumbnailView *blockSelf = weakSelf;
        if ([blockSelf.imageRep.url isEqualToString:[imageURL absoluteString]]) {
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
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        loadingView.center = self.center;
        loadingView.hidesWhenStopped = YES;
        [self addSubview:loadingView];
        self.loadingView = loadingView;
    }

    self.imageView.hidden = YES;
    [self.loadingView startAnimating];
    
    [[MobileRequestOperation defaultQueue] addOperation:request];
}

@end
