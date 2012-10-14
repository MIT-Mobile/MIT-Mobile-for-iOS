#import <UIKit/UIKit.h>


@interface MITScannerOverlayView : UIView

@property (nonatomic) BOOL highlighted;
@property (nonatomic,retain) UIColor *highlightColor;
@property (nonatomic,retain) UIColor *outlineColor;
@property (nonatomic,retain) UIColor *overlayColor;
@property (nonatomic,retain) NSString *helpText;


// Returns the rect in pixels. This rect is in this view's
// coordinate system
- (CGRect)qrRect;

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
                                 duration: (NSTimeInterval) duration;
@end
