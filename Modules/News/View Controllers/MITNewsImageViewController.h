#import <UIKit/UIKit.h>

@class MITNewsImage;

@interface MITNewsImageViewController : UIViewController
@property (nonatomic,weak) IBOutlet UIActivityIndicatorView *imageLoadingIndicator;
@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet UIImageView *imageView;

@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) MITNewsImage *image;

@end
