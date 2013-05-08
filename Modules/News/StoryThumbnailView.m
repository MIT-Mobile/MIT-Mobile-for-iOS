#import "StoryThumbnailView.h"
#import "MIT_MobileAppDelegate.h"
#import "CoreDataManager.h"
#import "NewsImageRep.h"
#import "MobileRequestOperation.h"

@interface StoryThumbnailView (Private)

+ (UIImage *)placeholderImage;

@end


@implementation StoryThumbnailView

@synthesize imageRep, imageData, loadingView, imageView;

+ (UIImage *)placeholderImage {
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
        imageRep = nil;
        imageData = nil;
        loadingView = nil;
        imageView = nil;
        self.opaque = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
    }
    return self;
}

- (void)setImageRep:(NewsImageRep *)newImageRep {
    if (![newImageRep isEqual:imageRep]) {
        [imageRep release];
        imageRep = [newImageRep retain];
        imageView.image = nil;
        imageView.hidden = YES;

        if (self.loadingView) {
            [self.loadingView stopAnimating];
            self.loadingView.hidden = YES;
        }
        if (imageRep) {
            self.backgroundColor = [UIColor colorWithWhite:0.60 alpha:1.0];
        } else {
            self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
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
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
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
    if ([[imageRep.url pathExtension] length] == 0) {
        self.backgroundColor = [UIColor colorWithPatternImage:[StoryThumbnailView placeholderImage]];
        return;
    }
    
    NSString *imageURLString = imageRep.url;
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithURL:[NSURL URLWithString:imageURLString] parameters:nil] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *request, NSData *data, NSString *contentType, NSError *error) {
        if ([self.imageRep.url isEqualToString:imageURLString]) {
            if (error) {
                self.imageData = nil;
            } else {
                self.imageData = data;
                BOOL validImage = [self displayImage];
                if (validImage) {
                    imageRep.data = data;
                    [CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
                }
            }
        }
    };

    self.imageData = nil;
    
    if (!self.loadingView) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:self.loadingView];
        loadingView.center = self.center;
    }
    imageView.hidden = YES;
    loadingView.hidden = NO;
    [loadingView startAnimating];
    
    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)dealloc {
    [imageData release];
    imageData = nil;
    [loadingView release];
    [imageView release];
    [super dealloc];
}

@end
