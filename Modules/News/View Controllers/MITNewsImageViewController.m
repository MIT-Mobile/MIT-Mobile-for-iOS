#import "MITNewsImageViewController.h"
#import "UIImageView+WebCache.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"
#import "MITImageScrollView.h"

@implementation MITNewsImageViewController {
    NSManagedObjectID *_newsImageObjectID;
    MITNewsImage *_newsImageObject;
}

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
            MITNewsImageRepresentation *imageRepresentation = [self.image bestRepresentationForSize:MITNewsImageLargestImageSize];
            imageSize.width = [imageRepresentation.width doubleValue];
            imageSize.height = [imageRepresentation.height doubleValue];
            imageURL = imageRepresentation.url;
        }];
        
        __weak MITNewsImageViewController *weak = self;
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                              options:0
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                [self.imageLoadingIndicator stopAnimating];
                                                                
                                                                if (image) {
                                                                    [self.scrollView displayImage:image];
                                                                    MITNewsImageViewController *strong = weak;
                                                                    strong.cachedImage = image;
                                                                }
                                                            }];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.imageView cancelCurrentImageLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _newsImageObject = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Properties
- (void)setImage:(MITNewsImage *)image
{
    if (![_newsImageObjectID isEqual:image]) {
        _newsImageObjectID = [image objectID];
        _newsImageObject = nil;
    }
}

/** Returns the view's NewsImage entity.
 * Guaranteed to be in the local managed object context.
 */
- (MITNewsImage*)image
{
    if (!_newsImageObject) {
        if (_newsImageObjectID && _managedObjectContext) {
            [_managedObjectContext performBlockAndWait:^{
                NSError *error = nil;
                _newsImageObject = (MITNewsImage*)[_managedObjectContext existingObjectWithID:_newsImageObjectID error:&error];
            }];
        }
    }
    
    return _newsImageObject;
}

@end
