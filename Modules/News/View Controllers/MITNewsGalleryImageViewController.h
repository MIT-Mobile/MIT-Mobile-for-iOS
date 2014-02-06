#import <UIKit/UIKit.h>

@interface MITNewsGalleryImageViewController : UIViewController
@property (nonatomic,weak) IBOutlet UIActivityIndicatorView *imageLoadingIndicator;
@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet UIImageView *imageView;

@property (nonatomic,weak) IBOutlet NSLayoutConstraint *topContentConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *bottomContentConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *leadingContentConstraint;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint *trailingContentConstraint;

@property (nonatomic,strong) NSURL *imageURL;

@end
