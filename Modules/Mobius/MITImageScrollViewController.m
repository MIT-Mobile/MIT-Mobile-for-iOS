#import "MITImageScrollViewController.h"
#import "MITImageScrollView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MITImageScrollViewController ()

@property (nonatomic, strong) MITImageScrollView *scrollView;

@end

@implementation MITImageScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollView = [[MITImageScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.scrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setImageURL:(NSURL *)imageURL {
    if (_imageURL != imageURL) {
        _imageURL = [imageURL copy];
        [self loadImageAsync:_imageURL];
    }
}

- (void)loadImageAsync:(NSURL *)url {
    dispatch_queue_t imageLoadingQueue = dispatch_queue_create("MIT image scroll view loading queue", NULL);
    dispatch_async(imageLoadingQueue, ^{
        __block NSURL *imageURL = url;
        
        __weak MITImageScrollViewController *weak = self;

        [[SDWebImageDownloader sharedDownloader]downloadImageWithURL:imageURL
                                                             options:0
                                                            progress:nil
                                                           completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                MITImageScrollViewController *strong = weak;
                                                                if (image) {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        self.image = image;
                                                                        [strong displayImage:image];
                                                                    });
                                                                }
                                                           }];
    });
}

- (void)displayImage:(UIImage *)image {
    [self.scrollView displayImage:image];
}

- (void)toggleZoom {
    [self.scrollView resetZoom];
}

@end
