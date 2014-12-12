#import <UIKit/UIKit.h>

@interface MITImageScrollView : UIScrollView
@property (nonatomic,readonly) CGPoint minimumContentOffset;
@property (nonatomic,readonly) CGPoint maximumContentOffset;

- (void)displayImage:(UIImage *)image;
- (void)resetZoom;
@end
