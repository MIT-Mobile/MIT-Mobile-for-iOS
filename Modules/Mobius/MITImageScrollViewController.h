#import <UIKit/UIKit.h>

@interface MITImageScrollViewController : UIViewController

@property (nonatomic, assign) NSInteger index;
@property (strong) UIImage *image;
@property (nonatomic, copy) NSURL *imageURL;

- (void)displayImage:(UIImage *)image;
- (void)toggleZoom;

@end
