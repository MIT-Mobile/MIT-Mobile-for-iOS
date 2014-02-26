#import <UIKit/UIKit.h>

@class MITNewsImage;
@class MITImageScrollView;

@interface MITNewsImageViewController : UIViewController
@property (nonatomic,weak) IBOutlet UIActivityIndicatorView *imageLoadingIndicator;
@property (nonatomic,weak) IBOutlet MITImageScrollView *scrollView;
@property (nonatomic,weak) IBOutlet UIImageView *imageView;

@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) MITNewsImage *image;
@property (nonatomic,weak) UIImage *cachedImage;

@end
