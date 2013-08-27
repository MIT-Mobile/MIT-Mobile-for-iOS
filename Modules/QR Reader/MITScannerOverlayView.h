#import <UIKit/UIKit.h>


@interface MITScannerOverlayView : UIView

@property (nonatomic) BOOL highlighted;
@property (nonatomic,strong) UIColor *highlightColor;
@property (nonatomic,strong) UIColor *outlineColor;
@property (nonatomic,strong) UIColor *overlayColor;
@property (nonatomic,copy) NSString *helpText;


// Returns the rect in pixels. This rect is in this view's
// coordinate system
- (CGRect)qrRect;

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration;
@end
